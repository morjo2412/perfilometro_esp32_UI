// UIManager.pde

class UIManager {
  private PApplet parent;
  private HashMap<String, Button> buttons;
  private HashMap<String, TextBox> textBoxes;
  private ArrayList<String> debugConsole;
  private int maxConsoleLines = 10;
  
  UIManager(PApplet p) {
    parent = p;
    buttons = new HashMap<String, Button>();
    textBoxes = new HashMap<String, TextBox>();
    debugConsole = new ArrayList<String>();
    initButtons();
    initTextBoxes();
  }
  
  void initButtons() {
    buttons.put("START", new Button(20, 100, 100, 40, "START", parent.color(0, 200, 0)));
    buttons.put("PAUSE", new Button(130, 100, 100, 40, "PAUSE", parent.color(200, 150, 0)));
    buttons.put("RESUME", new Button(240, 100, 100, 40, "RESUME", parent.color(0, 150, 200)));
    buttons.put("STOP", new Button(350, 100, 100, 40, "STOP", parent.color(200, 0, 0)));
    buttons.put("CANCEL", new Button(460, 100, 100, 40, "CANCEL", parent.color(150, 0, 0)));
    buttons.put("SAVE", new Button(20, 150, 100, 40, "SAVE", parent.color(100, 100, 200)));
    buttons.put("NEW", new Button(130, 150, 100, 40, "NEW", parent.color(100, 200, 100)));
    buttons.put("SEND_CONFIG", new Button(810, 100, 160, 40, "ENVIAR CONFIG", parent.color(50, 150, 200)));
    buttons.put("TOGGLE_MODE", new Button(810, 150, 160, 40, "SIMULADOR", parent.color(150, 100, 200)));
  }
  
  void initTextBoxes() {
    textBoxes.put("SPEED", new TextBox(620, 100, 80, 30, "800"));
    textBoxes.put("RESOLUTION", new TextBox(620, 135, 80, 30, "1.0"));
    textBoxes.put("AREA_X", new TextBox(710, 100, 40, 30, "50"));
    textBoxes.put("AREA_Y", new TextBox(760, 100, 40, 30, "50"));
  }
  
  void draw(State state, int progress, int total, String errorMsg, boolean isSimulator) {
    parent.camera();
    
    // Info panel
    parent.fill(0, 150);
    parent.noStroke();
    parent.rect(0, 0, parent.width, 220);
    
    // Estado
    parent.fill(255);
    parent.textAlign(LEFT);
    parent.textSize(18);
    parent.text("Estado: " + state, 20, 30);
    parent.text("Modo: " + (isSimulator ? "SIMULADOR" : "ESP32"), 20, 55);
    
    // Progreso
    if (state == State.CAPTURING) {
      parent.text("Puntos: " + progress + " / " + (total > 0 ? total : "?"), 250, 30);
      if (total > 0) {
        float percent = (float)progress / total * 100;
        parent.text(nf(percent, 0, 1) + "%", 250, 55);
      }
    } else if (state == State.COMPLETE) {
      parent.text("Puntos totales: " + progress, 250, 30);
    }
    
    // Labels config
    parent.textSize(12);
    parent.text("SPEED (μs):", 620, 95);
    parent.text("RES (mm):", 620, 130);
    parent.text("ÁREA:", 710, 95);
    parent.text("x", 750, 115);
    
    // TextBoxes
    for (TextBox tb : textBoxes.values()) {
      tb.draw();
    }
    
    // Error
    if (errorMsg != null && !errorMsg.isEmpty()) {
      parent.fill(255, 100, 100);
      parent.textSize(14);
      parent.text("ERROR: " + errorMsg, 450, 30);
    }
    
    // Consola debug
    drawDebugConsole();
    
    // Botones según estado
    drawButtons(state, isSimulator);
    
    parent.perspective();
  }
  
  void drawDebugConsole() {
    parent.fill(0, 100);
    parent.rect(600, 30, 380, 60);
    parent.fill(100, 255, 100);
    parent.textAlign(LEFT);
    parent.textSize(10);
    
    int y = 42;
    int start = max(0, debugConsole.size() - 5);
    for (int i = start; i < debugConsole.size(); i++) {
      parent.text(debugConsole.get(i), 605, y);
      y += 12;
    }
  }
  
  void addDebugLine(String line) {
    debugConsole.add(line);
    if (debugConsole.size() > maxConsoleLines) {
      debugConsole.remove(0);
    }
  }
  
  void drawButtons(State state, boolean isSimulator) {
    for (Button btn : buttons.values()) {
      btn.enabled = false;
    }
    
    // Toggle y config solo en IDLE
    buttons.get("TOGGLE_MODE").enabled = (state == State.IDLE);
    buttons.get("SEND_CONFIG").enabled = (state == State.IDLE);
    
    // Label muestra hacia dónde cambiar
    buttons.get("TOGGLE_MODE").label = isSimulator ? "→ ESP32" : "→ SIMULADOR";
    
    switch(state) {
      case IDLE:
        buttons.get("START").enabled = true;
        // TextBoxes editables
        for (TextBox tb : textBoxes.values()) {
          tb.editable = true;
        }
        break;
      case CAPTURING:
        buttons.get("PAUSE").enabled = true;
        buttons.get("STOP").enabled = true;
        // TextBoxes bloqueadas
        for (TextBox tb : textBoxes.values()) {
          tb.editable = false;
        }
        break;
      case PAUSED:
        buttons.get("RESUME").enabled = true;
        buttons.get("CANCEL").enabled = true;
        for (TextBox tb : textBoxes.values()) {
          tb.editable = false;
        }
        break;
      case ERROR_PAUSED:
        buttons.get("RESUME").enabled = true;
        buttons.get("CANCEL").enabled = true;
        for (TextBox tb : textBoxes.values()) {
          tb.editable = false;
        }
        break;
      case COMPLETE:
        buttons.get("SAVE").enabled = true;
        buttons.get("NEW").enabled = true;
        for (TextBox tb : textBoxes.values()) {
          tb.editable = false;
        }
        break;
    }
    
    for (Button btn : buttons.values()) {
      btn.draw();
    }
  }
  
  String checkButtonClick(int mx, int my) {
    for (String name : buttons.keySet()) {
      Button btn = buttons.get(name);
      if (btn.enabled && btn.isInside(mx, my)) {
        return name;
      }
    }
    return null;
  }
  
  void handleTextBoxClick(int mx, int my) {
    for (TextBox tb : textBoxes.values()) {
      if (tb.editable && tb.isInside(mx, my)) {
        tb.focused = true;
      } else {
        tb.focused = false;
      }
    }
  }
  
  void handleKeyPress(char key, int keyCode) {
    for (TextBox tb : textBoxes.values()) {
      if (tb.focused) {
        tb.handleKey(key, keyCode);
        break;
      }
    }
  }
  
  int[] getConfigValues() {
    int speed = Integer.parseInt(textBoxes.get("SPEED").text);
    float resolution = Float.parseFloat(textBoxes.get("RESOLUTION").text);
    int areaX = Integer.parseInt(textBoxes.get("AREA_X").text);
    int areaY = Integer.parseInt(textBoxes.get("AREA_Y").text);
    return new int[]{speed, (int)(resolution * 100), areaX, areaY};
  }
  
  float getResolution() {
    return Float.parseFloat(textBoxes.get("RESOLUTION").text);
  }
  
  void showError(String errorCode) {
    String[] errorMsgs = {
      "Motor atascado",
      "Sensor desconectado",
      "Límite alcanzado",
      "Error interno ESP32"
    };
    
    int code = Integer.parseInt(errorCode);
    if (code >= 1 && code <= 4) {
      println("ERROR " + errorCode + ": " + errorMsgs[code-1]);
    }
  }
  
  // Clase interna Button
  class Button {
    float x, y, w, h;
    String label;
    color baseColor;
    boolean enabled;
    
    Button(float x, float y, float w, float h, String label, color c) {
      this.x = x;
      this.y = y;
      this.w = w;
      this.h = h;
      this.label = label;
      this.baseColor = c;
      this.enabled = false;
    }
    
    void draw() {
      parent.stroke(255);
      parent.strokeWeight(2);
      
      if (enabled) {
        parent.fill(baseColor);
      } else {
        parent.fill(50);
      }
      
      parent.rect(x, y, w, h, 5);
      
      parent.fill(enabled ? 255 : 100);
      parent.textAlign(CENTER, CENTER);
      parent.textSize(14);
      parent.text(label, x + w/2, y + h/2);
    }
    
    boolean isInside(int mx, int my) {
      return mx > x && mx < x + w && my > y && my < y + h;
    }
  }
  
  // Clase TextBox
  class TextBox {
    float x, y, w, h;
    String text;
    boolean focused = false;
    boolean editable = true;
    
    TextBox(float x, float y, float w, float h, String defaultText) {
      this.x = x;
      this.y = y;
      this.w = w;
      this.h = h;
      this.text = defaultText;
    }
    
    void draw() {
      parent.stroke(focused ? parent.color(0, 200, 255) : parent.color(150));
      parent.strokeWeight(2);
      parent.fill(editable ? parent.color(30) : parent.color(50));
      parent.rect(x, y, w, h, 3);
      
      parent.fill(editable ? 255 : 150);
      parent.textAlign(CENTER, CENTER);
      parent.textSize(12);
      parent.text(text, x + w/2, y + h/2);
    }
    
    boolean isInside(int mx, int my) {
      return mx > x && mx < x + w && my > y && my < y + h;
    }
    
    void handleKey(char key, int keyCode) {
      if (!editable) return;
      
      if (keyCode == BACKSPACE && text.length() > 0) {
        text = text.substring(0, text.length() - 1);
      } else if (keyCode != BACKSPACE && keyCode != SHIFT && keyCode != CONTROL) {
        if ((key >= '0' && key <= '9') || key == '.') {
          text += key;
        }
      }
    }
  }
}
