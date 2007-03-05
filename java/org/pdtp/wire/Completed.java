package org.pdtp.wire;

public class Completed {
  public Completed() { }
  
  public Completed(String url, String host, int port, String hash) {
    this.url = url;
    this.host = host;
    this.port = port;
    this.hash = hash;
  }
  
  public String url;
  public String host;
  public int port;
  public String hash;
}
