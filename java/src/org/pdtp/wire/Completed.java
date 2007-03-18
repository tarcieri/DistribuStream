package org.pdtp.wire;

public class Completed {
  public Completed() { }
  
  public Completed(String url, String peer, int port, String hash, Range range) {
    this.url = url;
    this.peer = peer;
    this.port = port;
    this.hash = hash;
    this.range = range;
  }
  
  @Override
  public String toString() {
    return "[ " + url + " @ " + peer + ":" + port + " " + range + " hash=" + hash + "]"; 
  }
  
  public String url;
  public String peer;
  public int port;
  public String hash;
  public Range range;
}
