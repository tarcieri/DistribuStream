package org.pdtp;


public class Transfer extends Request {
  public enum Direction { IN, OUT };
    
  public Transfer(Chunk chunk, String peer,
                  Direction dir) {    
    this.chunk = chunk;
    this.peer = peer;
    this.direction = dir;
  }
  
  public Chunk getChunk() {
    return chunk;
  }

  public String getPeer() {
    return peer;
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
  
  public void start() {
    System.out.println("Starting transfer...");
    System.out.println(this);
    // .
    // .
    // .
    System.out.println("Transfer done.");    
  }
     
  private Chunk chunk;
  private String peer;
  private Direction direction;
}
