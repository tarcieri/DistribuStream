package org.pdtp.wire;

import org.pdtp.Chunk;

public class Request {
  public Request() {  }
  
  public Request(Chunk c) {
    this.url = c.getUrl();
    this.chunks = new Range(c.getChunkID());
  }
  
  public Request(String url, Range chunks) {
    this.url = url;
    this.chunks = chunks;
  }
  
  public String url;
  public Range chunks;  
}
