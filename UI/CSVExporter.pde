// CSVExporter.pde
class CSVExporter {
  private PApplet parent;
  private ArrayList<PVector> pointsToSave;
  
  CSVExporter(PApplet p) {
    parent = p;
  }
  
  void prepareToSave(ArrayList<PVector> points) {
    pointsToSave = new ArrayList<PVector>(points);
    parent.selectOutput("Guardar CSV", "csvFileSelected", 
                        new File(generateTimestampName()));
  }
  
  void writeCSV(File selection) {
    if (selection == null) {
      println("Guardado cancelado");
      return;
    }
    
    String path = selection.getAbsolutePath();
    if (!path.endsWith(".csv")) path += ".csv";
    
    PrintWriter output = parent.createWriter(path);
    output.println("x,y,z");
    
    for (PVector p : pointsToSave) {
      output.println(nf(p.x, 0, 4) + "," + nf(p.y, 0, 4) + "," + nf(p.z, 0, 4));
    }
    
    output.flush();
    output.close();
    
    println("✓ Guardado: " + path + " (" + pointsToSave.size() + " puntos)");
  }
  
  String generateTimestampName() {
    return "captura_" + year() + "-" + nf(month(), 2) + "-" + nf(day(), 2) + 
           "_" + nf(hour(), 2) + "-" + nf(minute(), 2) + "-" + nf(second(), 2) + ".csv";
  }
}
