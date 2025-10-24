// PointBuffer.pde

class PointBuffer {
  private ArrayList<PVector> points;
  
  PointBuffer() {
    points = new ArrayList<PVector>();
  }
  
  synchronized void add(PVector point) {
    points.add(point.copy());
  }
  
  synchronized ArrayList<PVector> getAll() {
    return new ArrayList<PVector>(points);
  }
  
  synchronized int size() {
    return points.size();
  }
  
  synchronized void clear() {
    points.clear();
  }
  
  synchronized float[] getMinMaxZ() {
    if (points.isEmpty()) {
      return new float[]{0, 0};
    }
    
    float minZ = Float.MAX_VALUE;
    float maxZ = Float.MIN_VALUE;
    
    for (PVector p : points) {
      if (p.z < minZ) minZ = p.z;
      if (p.z > maxZ) maxZ = p.z;
    }
    
    return new float[]{minZ, maxZ};
  }
}
