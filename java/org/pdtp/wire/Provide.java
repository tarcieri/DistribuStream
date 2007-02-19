package org.pdtp.wire;

import org.pdtp.Resource;

public class Provide {
  public Provide(Resource r) {
    this.byteRange = r.getRange();
    this.url = r.getUrl();    
  }
  
  public long chunkSize;
  public Range byteRange;
  public String url;
}
