package org.pdtp.wire;

public class Completed {
  public Completed() { }
  
  public Completed(String url, String peer, int port, String hash, Range range, String peerId) {
    this.url = url;
    this.peer = peer;
    this.port = port;
    this.hash = hash;
    this.range = range;
    this.peerId = peerId;
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
  public String peerId;
}
