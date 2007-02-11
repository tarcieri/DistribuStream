package org.pdtp;

import java.util.Set;
import java.util.concurrent.SynchronousQueue;

public class Transfer {
  public enum State     { STARTED, STOPPED, VERIFIED, UNVERIFIED };
  public enum Direction { IN, OUT };
    
  public Transfer(Chunk chunk, String peer,
                  Direction dir, State state) {
    this.chunk = chunk;
    this.peer = peer;
    this.state = state;
    this.direction = dir;
  }
  
  public Chunk getChunk() {
    return chunk;
  }

  public String getPeer() {
    return peer;
  }

  public State getState() {
    return state;
  }

  public Direction getDirection() {
    return direction;
  }

  @Override
  public String toString() {
    return peer.toString() + ":" + chunk.toString() + ":" + direction.toString();
  }
  
  @Override
  public int hashCode() {
    return this.toString().hashCode();
  }
  
  public State block() {
    SynchronousQueue<State> mine;
    synchronized(this) {
      mine = new SynchronousQueue<State>();
      queues.add(mine);
    }    
    
    State s = mine.poll();
    
    synchronized(this) {
      queues.remove(mine);
    }
    
    return s;
  }
  
  protected void transition(State s) {
    if(!this.state.equals(s)) {
      for(SynchronousQueue<State> q : queues) {
        try {
          q.put(s);
        } catch (InterruptedException e) { }
      }
    }
  }
  
  public void start() {
    System.out.println("Starting transfer...");
    System.out.println(this);
    // .
    // .
    // .
    System.out.println("Transfer done.");    
  }
  
  private Set<SynchronousQueue<State>> queues;
  private Chunk chunk;
  private String peer;
  private State state;
  private Direction direction;  
}
