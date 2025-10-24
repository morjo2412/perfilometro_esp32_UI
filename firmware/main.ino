// ESP32 Perfilómetro 3D - Sistema H-Bot
// Compatible con Processing Control Software
// ===== COMANDOS SERIAL DISPONIBLES =====
// 
// CONFIGURACIÓN (Solo en estado IDLE, antes de START):
//   SPEED:valor        - Ajusta velocidad motor (stepDelay en μs). Ej: SPEED:150
//   RESOLUTION:valor   - Resolución de escaneo en mm. Ej: RESOLUTION:0.5
//   AREA:x,y          - Área de escaneo en mm. Ej: AREA:50,50
//
// CONTROL DE ESCANEO:
//   START             - Inicia escaneo (ejecuta homing primero)
//   PAUSE             - Pausa escaneo (solo durante CAPTURING)
//   RESUME            - Reanuda escaneo (solo durante PAUSED)
//   STOP              - Finaliza escaneo anticipadamente
//   CANCEL            - Cancela y regresa a home
//
// RESPUESTAS:
//   ACK:comando       - Confirmación de comando recibido
//   x,y,z             - Datos de punto escaneado
//   END               - Escaneo completado
//   ERROR:código      - Código de error

// ===== CONFIGURACIÓN DE PINES =====
// Motores paso a paso
#define STEP_PIN_X 14
#define DIR_PIN_X 12
#define LIMIT_SWITCH_X 15

#define STEP_PIN_Y 26
#define DIR_PIN_Y 27
#define LIMIT_SWITCH_Y 4

// Sensor de 4 cuadrantes
#define SENSOR_A0 34
#define SENSOR_A1 35
#define SENSOR_A2 32
#define SENSOR_A3 33

// ===== CONFIGURACIÓN DE PARÁMETROS =====
#define AVANCE LOW
#define RETROCESO HIGH
//#define STEP_DELAY 800  // microsegundos
int stepDelay = 800;
#define STEPS_PER_MM 5
//#define MAX_X_MM 75
//#define MAX_Y_MM 70
//#define SCAN_RESOLUTION_MM  1
int maxXmm = 10;
int maxYmm = 10;
float scanResolution = 1.0;

// ===== VARIABLES GLOBALES =====
bool isPaused = false;
bool isScanning = false;
float currentX = 0;
float currentY = 0;
int direction = AVANCE;

// ===== SETUP =====
void setup() {
  Serial.begin(115200);
  
  pinMode(STEP_PIN_X, OUTPUT);
  pinMode(DIR_PIN_X, OUTPUT);
  pinMode(STEP_PIN_Y, OUTPUT);
  pinMode(DIR_PIN_Y, OUTPUT);
  
  pinMode(LIMIT_SWITCH_X, INPUT_PULLUP);
  pinMode(LIMIT_SWITCH_Y, INPUT_PULLUP);
  
  pinMode(SENSOR_A0, INPUT);
  pinMode(SENSOR_A1, INPUT);
  pinMode(SENSOR_A2, INPUT);
  pinMode(SENSOR_A3, INPUT);
  
  Serial.println("ESP32 Perfilómetro H-Bot iniciado");
  Serial.println("Esperando comando START...");
}

// ===== LOOP PRINCIPAL =====
void loop() {
  processSerialCommands();
  
  if (isScanning && !isPaused) {
    performScan();
  }
}

// ===== FUNCIONES DE COMUNICACIÓN SERIAL =====
void processSerialCommands() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    Serial.println("ACK:" + command);

    if (command.startsWith("SPEED:")) {
      if (!isScanning) {
        stepDelay = command.substring(6).toInt();
        Serial.println("Velocidad ajustada a: " + String(stepDelay) + " μs");
      } else {
        Serial.println("ERROR:05");  // No se puede cambiar durante escaneo
      }
      return;
    }

    if (command.startsWith("RESOLUTION:")) {
      if (!isScanning) {
        scanResolution = command.substring(11).toFloat();
        Serial.println("Resolución: " + String(scanResolution) + " mm");
      } else {
        Serial.println("ERROR:05");
      }
      return;
    }
    
    if (command.startsWith("AREA:")) {
      if (!isScanning) {
        int separador = command.indexOf(',', 5);
        maxXmm = command.substring(5, separador).toInt();
        maxYmm = command.substring(separador + 1).toInt();
        Serial.println("Área: " + String(maxXmm) + "x" + String(maxYmm) + " mm");
      } else {
        Serial.println("ERROR:05");
      }
      return;
    }
    
    if (command == "START") {
      handleStart();
    } 
    else if (command == "PAUSE") {
      handlePause();
    }
    else if (command == "RESUME") {
      handleResume();
    }
    else if (command == "STOP") {
      handleStop();
    }
    else if (command == "CANCEL") {
      handleCancel();
    }
  }
}

void handleStart() {
  Serial.println("Iniciando escaneo...");
  homing();
  currentX = 0;
  currentY = 0;
  direction = AVANCE;
  isScanning = true;
  isPaused = false;
}

void handlePause() {
  isPaused = true;
  Serial.println("Escaneo pausado");
}

void handleResume() {
  isPaused = false;
  Serial.println("Escaneo resumido");
}

void handleStop() {
  isScanning = false;
  isPaused = false;
  Serial.println("END");
  Serial.println("Escaneo completado");
}

void handleCancel() {
  isScanning = false;
  isPaused = false;
  homing();
  Serial.println("Escaneo cancelado");
}

// ===== FUNCIONES DE ESCANEO =====
void performScan() {
  int z = readZ();
  sendData((int)currentX, (int)currentY, z);
  
  if (direction == AVANCE) {
    if (currentX < maxXmm - scanResolution ) {
      moveXYStepperMotor(distanceToSteps(scanResolution ), true, true);
      currentX += scanResolution ;
    } else {
      if (currentY < maxYmm - scanResolution ) {
        moveXYStepperMotor(distanceToSteps(scanResolution ), false, true);
        currentY += scanResolution ;
        direction = RETROCESO;
      } else {
        handleStop();
      }
    }
  } else { // RETROCESO
    if (currentX > 0) {
      moveXYStepperMotor(distanceToSteps(scanResolution ), true, false);
      currentX -= scanResolution ;
    } else {
      if (currentY < maxYmm - scanResolution ) {
        moveXYStepperMotor(distanceToSteps(scanResolution ), false, true);
        currentY += scanResolution ;
        direction = AVANCE;
      } else {
        handleStop();
      }
    }
  }
  
  delay(10);
}

// ===== FUNCIONES DE SENSOR =====
int readZ() {
  int v1 = analogRead(SENSOR_A0);
  int v2 = analogRead(SENSOR_A1);
  int v3 = analogRead(SENSOR_A2);
  int v4 = analogRead(SENSOR_A3);
  
  int total = v1 + v2 + v3 + v4;
  
  if (total < 100) {
    return 0;
  }
  
  float posX = float(v2 + v3 - v1 - v4) / total;
  float posY = float(v1 + v2 - v3 - v4) / total;
  
  int z = map(total, 100, 4095, 0, 1000);
  
  return z;
}

void sendData(int x, int y, int z) {
  Serial.print(x);
  Serial.print(",");
  Serial.print(y);
  Serial.print(",");
  Serial.println(z);
}

// ===== FUNCIONES DE CONTROL DE MOTORES H-BOT =====
void homing() {
  Serial.println("Ejecutando homing...");
  
  // Homing X: ambos motores retroceden juntos
  while (digitalRead(LIMIT_SWITCH_X) == HIGH) {
    moveXYStepperMotor(1, true, false);
    delay(2);
  }
  
  // Homing Y: motores en sentidos opuestos
  while (digitalRead(LIMIT_SWITCH_Y) == HIGH) {
    moveXYStepperMotor(1, false, false);
    delay(2);
  }
  
  // Alejarse de switches
  moveXYStepperMotor(distanceToSteps(5), true, true);
  moveXYStepperMotor(distanceToSteps(5), false, true);
  
  Serial.println("Homing completado");
}

void moveXYStepperMotor(int steps, bool moveInX, bool forward) {
  // Configurar direcciones según eje
  if (moveInX) {
    // Movimiento X: ambos motores MISMO sentido
    int dir = forward ? AVANCE : RETROCESO;
    digitalWrite(DIR_PIN_X, dir);
    digitalWrite(DIR_PIN_Y, dir);
  } else {
    // Movimiento Y: motores SENTIDOS OPUESTOS
    if (forward) {
      digitalWrite(DIR_PIN_X, RETROCESO);
      digitalWrite(DIR_PIN_Y, AVANCE);
    } else {
      digitalWrite(DIR_PIN_X, AVANCE);
      digitalWrite(DIR_PIN_Y, RETROCESO);
    }
  }
  
  delayMicroseconds(5);
  
  // Generar pulsos simultáneos
  for (int i = 0; i < steps; i++) {
    if (isPaused) {
      while (isPaused) {
        processSerialCommands();
        delay(10);
      }
    }
    
    digitalWrite(STEP_PIN_X, HIGH);
    digitalWrite(STEP_PIN_Y, HIGH);
    delayMicroseconds(stepDelay );
    digitalWrite(STEP_PIN_X, LOW);
    digitalWrite(STEP_PIN_Y, LOW);
    delayMicroseconds(stepDelay );
  }
}

int distanceToSteps(float distanceMM) {
  return (int)(distanceMM * STEPS_PER_MM);
}

// ===== MANEJO DE ERRORES =====
void sendError(int errorCode) {
  Serial.print("ERROR:");
  Serial.println(errorCode);
  isPaused = true;
  
  // 01 - Motor X atascado
  // 02 - Motor Y atascado  
  // 03 - Sensor desconectado
  // 04 - Límite no detectado
  // 05 - Comando inválido durante escaneo
}

bool checkSensorConnection() {
  int total = analogRead(SENSOR_A0) + analogRead(SENSOR_A1) + 
              analogRead(SENSOR_A2) + analogRead(SENSOR_A3);
  
  if (total < 10) {
    sendError(3);
    return false;
  }
  return true;
}
