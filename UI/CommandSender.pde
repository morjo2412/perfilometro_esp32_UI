// CommandSender.pde

import processing.serial.*;
import java.util.concurrent.*;

class CommandSender {
  private Serial port;
  private ConcurrentLinkedQueue<String> commandQueue;
  private final int TIMEOUT_MS = 2000;
  private final int MAX_RETRIES = 3;
  
  CommandSender(Serial serialPort, ConcurrentLinkedQueue<String> cmdQueue) {
    port = serialPort;
    commandQueue = cmdQueue;
  }
  
  boolean sendWithACK(String command) {
    for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      println("Enviando: " + command + " (intento " + attempt + "/" + MAX_RETRIES + ")");
      send(command);
      
      if (waitForACK(command)) {
        println("✓ ACK recibido para: " + command);
        return true;
      }
      
      println("✗ Timeout esperando ACK para: " + command);
      if (attempt < MAX_RETRIES) delay(500);
    }
    
    println("✗ Falló después de " + MAX_RETRIES + " intentos: " + command);
    return false;
  }
  
  void send(String text) {
    if (port != null) {
      port.write(text + "\n");
    }
  }
  
  private boolean waitForACK(String command) {
    String expectedACK = "ACK:" + command;
    long startTime = millis();
    
    while (millis() - startTime < TIMEOUT_MS) {
      if (!commandQueue.isEmpty()) {
        String response = commandQueue.poll();
        if (response != null && response.equals(expectedACK)) {
          return true;
        }
      }
      delay(10);
    }
    
    return false;
  }
}
