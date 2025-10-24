// StateMachine.pde

enum State {
  IDLE,
  CAPTURING,
  PAUSED,
  ERROR_PAUSED,
  COMPLETE
}

class StateMachine {
  private State currentState;
  private HashMap<State, ArrayList<State>> transitionMap;
  
  StateMachine() {
    currentState = State.IDLE;
    initTransitionMap();
  }
  
  private void initTransitionMap() {
    transitionMap = new HashMap<State, ArrayList<State>>();
    
    // IDLE → CAPTURING
    ArrayList<State> idleTransitions = new ArrayList<State>();
    idleTransitions.add(State.CAPTURING);
    transitionMap.put(State.IDLE, idleTransitions);
    
    // CAPTURING → PAUSED, ERROR_PAUSED, COMPLETE
    ArrayList<State> capturingTransitions = new ArrayList<State>();
    capturingTransitions.add(State.PAUSED);
    capturingTransitions.add(State.ERROR_PAUSED);
    capturingTransitions.add(State.COMPLETE);
    transitionMap.put(State.CAPTURING, capturingTransitions);
    
    // PAUSED → CAPTURING, IDLE
    ArrayList<State> pausedTransitions = new ArrayList<State>();
    pausedTransitions.add(State.CAPTURING);
    pausedTransitions.add(State.IDLE);
    transitionMap.put(State.PAUSED, pausedTransitions);
    
    // ERROR_PAUSED → CAPTURING, IDLE
    ArrayList<State> errorPausedTransitions = new ArrayList<State>();
    errorPausedTransitions.add(State.CAPTURING);
    errorPausedTransitions.add(State.IDLE);
    transitionMap.put(State.ERROR_PAUSED, errorPausedTransitions);
    
    // COMPLETE → IDLE
    ArrayList<State> completeTransitions = new ArrayList<State>();
    completeTransitions.add(State.IDLE);
    transitionMap.put(State.COMPLETE, completeTransitions);
  }
  
  boolean setState(State newState) {
    if (canTransition(newState)) {
      currentState = newState;
      println("Estado cambiado a: " + newState);
      return true;
    }
    println("Transición inválida: " + currentState + " → " + newState);
    return false;
  }
  
  boolean canTransition(State target) {
    ArrayList<State> validTransitions = transitionMap.get(currentState);
    return validTransitions != null && validTransitions.contains(target);
  }
  
  State getState() {
    return currentState;
  }
  
  boolean isCapturing() {
    return currentState == State.CAPTURING;
  }
  
  boolean isPaused() {
    return currentState == State.PAUSED || currentState == State.ERROR_PAUSED;
  }
  
  boolean isErrorPaused() {
    return currentState == State.ERROR_PAUSED;
  }
  
  boolean isComplete() {
    return currentState == State.COMPLETE;
  }
  
  boolean isIdle() {
    return currentState == State.IDLE;
  }
}
