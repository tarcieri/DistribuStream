package org.pdtp.wire;

public class Transfer {
  public Transfer() { }
  
  public String url;
  public long chunkID;   
  
  public String host;
  public int port;
  
  public String method;
  //public String transferUrl;
  public Range byteRange;
}
