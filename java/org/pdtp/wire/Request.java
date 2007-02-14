package org.pdtp.wire;

import org.pdtp.Resource;

public class Request {
  public Request() {  }
  
  public Request(Resource c) {
    this.url = c.getUrl();
    this.chunks = c.getRange();
  }
  
  public Request(String url, Range chunks) {
    this.url = url;
    this.chunks = chunks;
  }
  
  public String url;
  public Range chunks;  
}
