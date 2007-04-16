package org.pdtp.wire;

public class Completed {
  public Completed() { }
  
  public Completed(String url, String hash, Range range, String peerId) {
    this.url = url;
    this.hash = hash;
    this.range = range;
    this.peerId = peerId;
  }
  
  @Override
  public String toString() {
    return "[ " + url + " @ " + peerId + " " + range + " hash=" + hash + "]"; 
  }
  
  public String url;
  public String hash;
  public Range range;
  public String peerId;
}
