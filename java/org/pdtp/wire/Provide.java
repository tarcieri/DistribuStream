package org.pdtp.wire;

import org.pdtp.Resource;

public class Provide {
  public Provide(Resource r) {
    this.chunkRange = r.getRange();
    this.url = r.getUrl();
  }
  
  public Range chunkRange;
  public String url;
}
