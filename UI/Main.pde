// PerfilometroSimulator.pde
import processing.serial.*;
import java.util.concurrent.*;

// Componentes
StateMachine stateMachine;
PointBuffer pointBuffer;
ShapeManager shapeManager;
CSVExporter csvExporter;
UIManager uiManager;
SimuladorESP32 simulador;
SerialReaderThread serialReader;
CommandSender commandSender;

// Queues
ConcurrentLinkedQueue<PVector> dataQueue;
ConcurrentLinkedQueue<String> commandQueue;
ConcurrentLinkedQueue<String> debugQueue;

// Config
int gridX = 50, gridY = 50;
int viewMode = 0;
float angleX = 0, angleY = 0, angleZ = 0;
float zoom = 1;
int lastMouseX, lastMouseY;
String lastError = "";

// Modo operación
boolean useSimulator = true;
String serialPort = "/dev/ttyUSB0"; // Cambiar según tu sistema
int baudRate = 115200;

// Config ESP32
int speedConfig = 800;
float resolutionConfig = 1.0;
int areaXConfig = 50;
int areaYConfig = 50;

void setup() {
  size(1000, 800, P3D);
  
  dataQueue = new ConcurrentLinkedQueue<PVector>();
  commandQueue = new ConcurrentLinkedQueue<String>();
  debugQueue = new ConcurrentLinkedQueue<String>();
  
  stateMachine = new StateMachine();
  pointBuffer = new PointBuffer();
  shapeManager = new ShapeManager(this);
  csvExporter = new CSVExporter(this);
  uiManager = new UIManager(this);
  
  simulador = new SimuladorESP32(dataQueue, commandQueue);
  simulador.updateConfig(areaXConfig, areaYConfig, resolutionConfig);
  
  println("Sistema listo (Modo: Simulador)");
  println("Puertos serial disponibles:");
  printArray(Serial.list());
}

void draw() {
  background(20);
  
  processDataQueue();
  processCommandQueue();
  processDebugQueue();
  
  // Actualizar grid según configuración
  gridX = areaXConfig;
  gridY = areaYConfig;
  
  if (stateMachine.isCapturing() && pointBuffer.size() > 0) {
    shapeManager.updatePointsShape(pointBuffer.getAll());
  }
  
  if (pointBuffer.size() > 0) render3D();
  
  uiManager.draw(stateMachine.getState(), pointBuffer.size(), gridX * gridY, lastError, useSimulator);
}

void processDebugQueue() {
  while (!debugQueue.isEmpty()) {
    uiManager.addDebugLine(debugQueue.poll());
  }
}

void processDataQueue() {
  while (!dataQueue.isEmpty()) {
    pointBuffer.add(dataQueue.poll());
  }
}

void processCommandQueue() {
  while (!commandQueue.isEmpty()) {
    String cmd = commandQueue.poll();
    
    if (cmd.startsWith("ERROR:")) {
      lastError = "Código " + cmd.substring(6);
      uiManager.showError(cmd.substring(6));
      stateMachine.setState(State.ERROR_PAUSED);
    } else if (cmd.equals("END")) {
      if (pointBuffer.size() == gridX * gridY) {
        stateMachine.setState(State.COMPLETE);
        shapeManager.generateAllVisuals(pointBuffer.getAll(), gridX, gridY);
      }
    }
  }
}

void render3D() {
  lights();
  translate(width/2, height/2 + 110);
  scale(zoom);
  
  if (viewMode == 4) rotateZ(angleZ);
  else { rotateX(angleX); rotateY(angleY); }
  
  strokeWeight(2);
  stroke(255, 0, 0); line(0, 0, 0, 300, 0, 0);
  stroke(0, 255, 0); line(0, 0, 0, 0, 300, 0);
  stroke(0, 0, 255); line(0, 0, 0, 0, 0, 150);
  
  PShape shape = stateMachine.isComplete() ? 
    shapeManager.getCurrentShape(viewMode) : 
    shapeManager.getCurrentShape(0);
  
  if (shape != null) shape(shape);
}

void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  
  // Check textboxes first
  uiManager.handleTextBoxClick(mouseX, mouseY);
  
  String cmd = uiManager.checkButtonClick(mouseX, mouseY);
  if (cmd != null) {
    if (cmd.equals("SEND_CONFIG")) {
      int[] config = uiManager.getConfigValues();
      speedConfig = config[0];
      resolutionConfig = config[1] / 100.0;
      areaXConfig = config[2];
      areaYConfig = config[3];
    }
    handleCommand(cmd);
  }
}

void mouseDragged() {
  if (mouseY > 220) {
    float dx = (mouseX - lastMouseX) * 0.01;
    float dy = (mouseY - lastMouseY) * 0.01;
    
    if (viewMode == 4) angleZ += dx;
    else { angleY += dx; angleX += dy; }
  }
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void mouseWheel(MouseEvent e) {
  zoom = constrain(zoom * (1 - e.getCount() * 0.1), 0.1, 3);
}

void handleCommand(String cmd) {
  switch(cmd) {
    case "START":
      // Sincronizar config con textboxes antes de iniciar
      int[] config = uiManager.getConfigValues();
      speedConfig = config[0];
      resolutionConfig = config[1] / 100.0;
      areaXConfig = config[2];
      areaYConfig = config[3];
      
      if (useSimulator && simulador != null) {
        simulador.updateConfig(areaXConfig, areaYConfig, resolutionConfig);
      }
      
      sendDeviceCommand("START");
      stateMachine.setState(State.CAPTURING);
      pointBuffer.clear();
      shapeManager.clearShapes();
      lastError = "";
      break;
    case "PAUSE":
      sendDeviceCommand("PAUSE");
      stateMachine.setState(State.PAUSED);
      break;
    case "RESUME":
      sendDeviceCommand("RESUME");
      stateMachine.setState(State.CAPTURING);
      lastError = "";
      break;
    case "STOP":
      sendDeviceCommand("STOP");
      stateMachine.setState(State.COMPLETE);
      shapeManager.generateAllVisuals(pointBuffer.getAll(), gridX, gridY);
      break;
    case "CANCEL":
      sendDeviceCommand("CANCEL");
      pointBuffer.clear();
      shapeManager.clearShapes();
      stateMachine.setState(State.IDLE);
      break;
    case "SAVE":
      csvExporter.prepareToSave(pointBuffer.getAll());
      break;
    case "NEW":
      pointBuffer.clear();
      shapeManager.clearShapes();
      stateMachine.setState(State.IDLE);
      viewMode = 0;
      break;
    case "TOGGLE_MODE":
      if (stateMachine.isIdle()) {
        toggleMode();
      }
      break;
    case "SEND_CONFIG":
      if (stateMachine.isIdle()) {
        sendConfiguration();
      }
      break;
  }
}

void sendDeviceCommand(String cmd) {
  if (useSimulator) {
    simulador.receiveCommand(cmd);
  } else {
    if (commandSender != null) {
      commandSender.sendWithACK(cmd);
    }
  }
}

void sendConfiguration() {
  if (useSimulator) {
    simulador.updateConfig(areaXConfig, areaYConfig, resolutionConfig);
    println("✓ Config simulador actualizada");
  } else {
    if (commandSender != null) {
      commandSender.send("SPEED:" + speedConfig);
      delay(100);
      commandSender.send("RESOLUTION:" + resolutionConfig);
      delay(100);
      commandSender.send("AREA:" + areaXConfig + "," + areaYConfig);
      println("✓ Config ESP32 enviada");
    }
  }
}

void toggleMode() {
  useSimulator = !useSimulator;
  
  if (useSimulator) {
    // Activar simulador
    if (serialReader != null) {
      serialReader.stopThread();
      serialReader = null;
    }
    commandSender = null;
    
    if (simulador == null || !simulador.isAlive()) {
      simulador = new SimuladorESP32(dataQueue, commandQueue);
      simulador.updateConfig(areaXConfig, areaYConfig, resolutionConfig);
    }
    println("✓ Modo: Simulador");
  } else {
    // Activar ESP32
    if (simulador != null) {
      simulador.stopThread();
    }
    
    try {
      Serial port = new Serial(this, serialPort, baudRate);
      serialReader = new SerialReaderThread(this, serialPort, baudRate, dataQueue, commandQueue, debugQueue);
      commandSender = new CommandSender(port, commandQueue);
      serialReader.start();
      println("✓ Modo: ESP32 conectado");
    } catch (Exception e) {
      println("✗ Error conectando ESP32: " + e.getMessage());
      useSimulator = true;
      println("✓ Volviendo a modo Simulador");
    }
  }
}

void keyPressed() {
  // Handle textbox input
  uiManager.handleKeyPress(key, keyCode);
  
  if ((key == 'v' || key == 'V') && stateMachine.isComplete()) {
    viewMode = (viewMode + 1) % 5;
  }
  if (key == 'r' || key == 'R') {
    angleX = angleY = angleZ = 0;
    zoom = 1;
  }
  
  // Teclas directas simulador
  if (key == 'e' && useSimulator && simulador != null) {
    simulador.sendError("02");
  }
}

void csvFileSelected(File selection) {
  csvExporter.writeCSV(selection);
}

void exit() {
  if (simulador != null) simulador.stopThread();
  if (serialReader != null) serialReader.stopThread();
  super.exit();
}

// Simulador ESP32
class SimuladorESP32 extends Thread {
  ConcurrentLinkedQueue<PVector> dq;
  ConcurrentLinkedQueue<String> cq;
  boolean capturing = false;
  boolean running = true;
  int pointCount = 0;
  
  // Config dinámica
  int maxX = 50;
  int maxY = 50;
  float resolution = 1.0;
  int maxPoints = 2500;
  
  SimuladorESP32(ConcurrentLinkedQueue<PVector> data, ConcurrentLinkedQueue<String> cmd) {
    dq = data;
    cq = cmd;
    start();
  }
  
  void updateConfig(int areaX, int areaY, float res) {
    maxX = areaX;
    maxY = areaY;
    resolution = res;
    maxPoints = (int)((maxX / resolution) * (maxY / resolution));
    println("Simulador config: " + maxX + "x" + maxY + "mm, res=" + resolution + "mm");
  }
  
  void run() {
    while (running) {
      if (capturing) {
        int cols = (int)(maxX / resolution);
        int rows = (int)(maxY / resolution);
        
        float x = (pointCount % cols) * resolution;
        float y = (pointCount / cols) * resolution;
        float z = 30 * sin(x * 0.1) * cos(y * 0.1);
        
        dq.offer(new PVector(x, y, z));
        pointCount++;
        
        if (pointCount >= cols * rows) {
          capturing = false;
          cq.offer("END");
          println("Captura completa: " + pointCount + " puntos");
        }
      }
      
      try { Thread.sleep(20); } 
      catch (InterruptedException e) { break; }
    }
  }
  
  void receiveCommand(String cmd) {
    cq.offer("ACK:" + cmd);
    
    if (cmd.equals("START")) {
      capturing = true;
      pointCount = 0;
    } else if (cmd.equals("RESUME")) {
      capturing = true;
    } else if (cmd.equals("PAUSE") || cmd.equals("STOP") || cmd.equals("CANCEL")) {
      capturing = false;
    }
  }
  
  void sendError(String code) {
    cq.offer("ERROR:" + code);
    capturing = false;
  }
  
  void stopThread() {
    running = false;
    interrupt();
  }
}
