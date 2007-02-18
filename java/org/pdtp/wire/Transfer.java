package org.pdtp.wire;

public class Transfer {
  public Transfer() { }
  
  public String url;
  public long chunkID;
  //public String peer;
  public String method;
  public String transferUrl;
  public Range byteRange;
}
