package org.pdtp.wire;

import org.pdtp.Resource;

public class Request {
  public Request() {  }
  
  public Request(Resource c) {
    this.url = c.getUrl();
    this.chunkRange = c.getRange();
  }
  
  public Request(String url, Range chunks) {
    this.url = url;
    this.chunkRange = chunks;
  }
  
  public String url;
  public Range chunkRange;
}
