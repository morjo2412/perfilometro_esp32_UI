// SerialReaderThread.pde
import processing.serial.*;
import java.util.concurrent.*;

class SerialReaderThread extends Thread {
  private Serial port;
  private ConcurrentLinkedQueue<PVector> dataQueue;
  private ConcurrentLinkedQueue<String> commandQueue;
  private ConcurrentLinkedQueue<String> debugQueue;
  private volatile boolean running;
  private String portName;
  private int baudRate;
  private PApplet parent;
  
  SerialReaderThread(PApplet p, String port, int baud, 
                     ConcurrentLinkedQueue<PVector> dq, 
                     ConcurrentLinkedQueue<String> cq,
                     ConcurrentLinkedQueue<String> dbg) {
    parent = p;
    portName = port;
    baudRate = baud;
    dataQueue = dq;
    commandQueue = cq;
    debugQueue = dbg;
    running = false;
  }
  
  void run() {
    running = true;
    connectSerial();
    
    while (running) {
      if (port != null && port.available() > 0) {
        try {
          String line = port.readStringUntil('\n');
          if (line != null) {
            line = line.trim();
            parseLine(line);
          }
        } catch (Exception e) {
          println("Error leyendo serial: " + e.getMessage());
        }
      }
      
      try {
        Thread.sleep(10);
      } catch (InterruptedException e) {
        break;
      }
    }
    
    if (port != null) {
      port.stop();
    }
  }
  
  void parseLine(String line) {
    if (line.isEmpty()) return;
    
    if (line.startsWith("ACK:")) {
      commandQueue.offer(line);
      println("→ " + line);
    } else if (line.startsWith("ERROR:")) {
      commandQueue.offer(line);
      println("→ " + line);
    } else if (line.equals("END")) {
      commandQueue.offer(line);
      println("→ END");
    } else {
      PVector point = parsePoint(line);
      if (point != null) {
        dataQueue.offer(point);
      } else {
        // Mensaje debug sin formato
        debugQueue.offer(line);
      }
    }
  }
  
  PVector parsePoint(String line) {
    try {
      String[] parts = line.split(",");
      if (parts.length == 3) {
        float x = Float.parseFloat(parts[0]);
        float y = Float.parseFloat(parts[1]);
        float z = Float.parseFloat(parts[2]);
        return new PVector(x, y, z);
      }
    } catch (NumberFormatException e) {
      println("Error parseando punto: " + line);
    }
    return null;
  }
  
  void connectSerial() {
    try {
      port = new Serial(parent, portName, baudRate);
      port.bufferUntil('\n');
      println("✓ Conectado a " + portName);
    } catch (Exception e) {
      println("✗ Error conectando: " + e.getMessage());
      port = null;
    }
  }
  
  void reconnect() {
    if (port != null) {
      port.stop();
    }
    delay(2000);
    connectSerial();
  }
  
  void stopThread() {
    running = false;
  }
  
  boolean isConnected() {
    return port != null;
  }
}
