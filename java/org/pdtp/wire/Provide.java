package org.pdtp.wire;

import org.pdtp.Resource;

public class Provide {
  public Provide(Resource r) {
    this.byteRange = r.getRange();
    this.url = r.getUrl();
    
    // This is a hack.
    // A bad, bad hack.
    this.chunkRange = new Range(byteRange.min() / 512, byteRange.max() / 512);
    this.chunkSize = 512;
  }
  
  public long chunkSize;
  public Range byteRange;
  public Range chunkRange;
  public String url;
}
