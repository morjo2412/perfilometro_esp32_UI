// ShapeManager.pde

class ShapeManager {
  private PApplet parent;
  private PShape pointsShape;
  private PShape meshShape;
  private PShape meshColorShape;
  private PShape surfaceShape;
  private PShape contourShape;
  
  ShapeManager(PApplet p) {
    parent = p;
  }
  
  void updatePointsShape(ArrayList<PVector> points) {
    if (points.isEmpty()) return;
    
    pointsShape = parent.createShape();
    pointsShape.beginShape(POINTS);
    pointsShape.strokeWeight(6);
    
    float[] minmax = getMinMaxZ(points);
    
    for (PVector p : points) {
      pointsShape.stroke(getHeightColor(p.z, minmax[0], minmax[1]));
      pointsShape.vertex(p.x, p.y, p.z);
    }
    
    pointsShape.endShape();
  }
  
  void generateAllVisuals(ArrayList<PVector> points, int gridX, int gridY) {
    int expectedSize = gridX * gridY;
    if (points.size() != expectedSize) {
      println("Error: Se esperan " + expectedSize + " puntos, hay " + points.size());
      return;
    }
    
    float[] minmax = getMinMaxZ(points);
    
    pointsShape = createPointsShape(points, minmax);
    meshShape = createMeshWireframe(points, gridX, gridY);
    meshColorShape = createMeshColored(points, gridX, gridY, minmax);
    surfaceShape = createSurface(points, gridX, gridY, minmax);
    contourShape = createContour2D(points, gridX, gridY, 20, minmax);
  }
  
  PShape getCurrentShape(int viewMode) {
    switch(viewMode) {
      case 0: return pointsShape;
      case 1: return meshShape;
      case 2: return meshColorShape;
      case 3: return surfaceShape;
      case 4: return contourShape;
      default: return pointsShape;
    }
  }
  
  void clearShapes() {
    pointsShape = meshShape = meshColorShape = surfaceShape = contourShape = null;
  }
  
  // === Generadores de geometría ===
  
  private PShape createPointsShape(ArrayList<PVector> pts, float[] minmax) {
    PShape s = parent.createShape();
    s.beginShape(POINTS);
    s.strokeWeight(6);
    
    for (PVector p : pts) {
      s.stroke(getHeightColor(p.z, minmax[0], minmax[1]));
      s.vertex(p.x, p.y, p.z);
    }
    
    s.endShape();
    return s;
  }
  
  private PShape createMeshWireframe(ArrayList<PVector> pts, int gX, int gY) {
    PShape s = parent.createShape();
    s.beginShape(LINES);
    s.stroke(150);
    s.strokeWeight(1);
    
    for (int j = 0; j < gY; j++) {
      for (int i = 0; i < gX - 1; i++) {
        int idx = j * gX + i;
        PVector p1 = pts.get(idx);
        PVector p2 = pts.get(idx + 1);
        s.vertex(p1.x, p1.y, p1.z);
        s.vertex(p2.x, p2.y, p2.z);
      }
    }
    
    for (int i = 0; i < gX; i++) {
      for (int j = 0; j < gY - 1; j++) {
        int idx = j * gX + i;
        PVector p1 = pts.get(idx);
        PVector p2 = pts.get(idx + gX);
        s.vertex(p1.x, p1.y, p1.z);
        s.vertex(p2.x, p2.y, p2.z);
      }
    }
    
    s.endShape();
    return s;
  }
  
  private PShape createMeshColored(ArrayList<PVector> pts, int gX, int gY, float[] minmax) {
    PShape s = parent.createShape();
    s.beginShape(LINES);
    s.strokeWeight(2);
    
    for (int j = 0; j < gY; j++) {
      for (int i = 0; i < gX - 1; i++) {
        int idx = j * gX + i;
        PVector p1 = pts.get(idx);
        PVector p2 = pts.get(idx + 1);
        s.stroke(getHeightColor(p1.z, minmax[0], minmax[1]));
        s.vertex(p1.x, p1.y, p1.z);
        s.stroke(getHeightColor(p2.z, minmax[0], minmax[1]));
        s.vertex(p2.x, p2.y, p2.z);
      }
    }
    
    for (int i = 0; i < gX; i++) {
      for (int j = 0; j < gY - 1; j++) {
        int idx = j * gX + i;
        PVector p1 = pts.get(idx);
        PVector p2 = pts.get(idx + gX);
        s.stroke(getHeightColor(p1.z, minmax[0], minmax[1]));
        s.vertex(p1.x, p1.y, p1.z);
        s.stroke(getHeightColor(p2.z, minmax[0], minmax[1]));
        s.vertex(p2.x, p2.y, p2.z);
      }
    }
    
    s.endShape();
    return s;
  }
  
  private PShape createSurface(ArrayList<PVector> pts, int gX, int gY, float[] minmax) {
    PShape s = parent.createShape();
    s.beginShape(TRIANGLES);
    s.noStroke();
    
    for (int j = 0; j < gY - 1; j++) {
      for (int i = 0; i < gX - 1; i++) {
        int idx = j * gX + i;
        PVector p1 = pts.get(idx);
        PVector p2 = pts.get(idx + 1);
        PVector p3 = pts.get(idx + gX + 1);
        PVector p4 = pts.get(idx + gX);
        
        s.fill(getHeightColor(p1.z, minmax[0], minmax[1]));
        s.vertex(p1.x, p1.y, p1.z);
        s.fill(getHeightColor(p2.z, minmax[0], minmax[1]));
        s.vertex(p2.x, p2.y, p2.z);
        s.fill(getHeightColor(p3.z, minmax[0], minmax[1]));
        s.vertex(p3.x, p3.y, p3.z);
        
        s.fill(getHeightColor(p1.z, minmax[0], minmax[1]));
        s.vertex(p1.x, p1.y, p1.z);
        s.fill(getHeightColor(p3.z, minmax[0], minmax[1]));
        s.vertex(p3.x, p3.y, p3.z);
        s.fill(getHeightColor(p4.z, minmax[0], minmax[1]));
        s.vertex(p4.x, p4.y, p4.z);
      }
    }
    
    s.endShape();
    return s;
  }
  
  private PShape createContour2D(ArrayList<PVector> pts, int gX, int gY, int levels, float[] minmax) {
    PShape s = parent.createShape();
    s.beginShape(LINES);
    s.strokeWeight(2);
    
    float baseZ = minmax[0] - 50;
    
    for (int level = 0; level < levels; level++) {
      float contourZ = PApplet.map(level, 0, levels - 1, minmax[0], minmax[1]);
      color contourColor = getHeightColor(contourZ, minmax[0], minmax[1]);
      
      for (int j = 0; j < gY - 1; j++) {
        for (int i = 0; i < gX - 1; i++) {
          int idx = j * gX + i;
          PVector p1 = pts.get(idx);
          PVector p2 = pts.get(idx + 1);
          PVector p3 = pts.get(idx + gX + 1);
          PVector p4 = pts.get(idx + gX);
          
          ArrayList<PVector> intersections = new ArrayList<PVector>();
          
          if ((p1.z <= contourZ && p2.z >= contourZ) || (p1.z >= contourZ && p2.z <= contourZ)) {
            float t = (contourZ - p1.z) / (p2.z - p1.z);
            intersections.add(new PVector(PApplet.lerp(p1.x, p2.x, t), PApplet.lerp(p1.y, p2.y, t), baseZ));
          }
          
          if ((p2.z <= contourZ && p3.z >= contourZ) || (p2.z >= contourZ && p3.z <= contourZ)) {
            float t = (contourZ - p2.z) / (p3.z - p2.z);
            intersections.add(new PVector(PApplet.lerp(p2.x, p3.x, t), PApplet.lerp(p2.y, p3.y, t), baseZ));
          }
          
          if ((p3.z <= contourZ && p4.z >= contourZ) || (p3.z >= contourZ && p4.z <= contourZ)) {
            float t = (contourZ - p3.z) / (p4.z - p3.z);
            intersections.add(new PVector(PApplet.lerp(p3.x, p4.x, t), PApplet.lerp(p3.y, p4.y, t), baseZ));
          }
          
          if ((p4.z <= contourZ && p1.z >= contourZ) || (p4.z >= contourZ && p1.z <= contourZ)) {
            float t = (contourZ - p4.z) / (p1.z - p4.z);
            intersections.add(new PVector(PApplet.lerp(p4.x, p1.x, t), PApplet.lerp(p4.y, p1.y, t), baseZ));
          }
          
          if (intersections.size() == 2) {
            s.stroke(contourColor);
            s.vertex(intersections.get(0).x, intersections.get(0).y, intersections.get(0).z);
            s.vertex(intersections.get(1).x, intersections.get(1).y, intersections.get(1).z);
          }
        }
      }
    }
    
    s.endShape();
    return s;
  }
  
  // === Utilidades ===
  
  private float[] getMinMaxZ(ArrayList<PVector> pts) {
    if (pts.isEmpty()) return new float[]{0, 0};
    
    float minZ = Float.MAX_VALUE;
    float maxZ = Float.MIN_VALUE;
    
    for (PVector p : pts) {
      if (p.z < minZ) minZ = p.z;
      if (p.z > maxZ) maxZ = p.z;
    }
    
    return new float[]{minZ, maxZ};
  }
  
  private color getHeightColor(float z, float minZ, float maxZ) {
    float t = PApplet.map(z, minZ, maxZ, 0, 1);
    return parent.lerpColor(parent.color(50, 100, 255), parent.color(255, 50, 50), t);
  }
}
