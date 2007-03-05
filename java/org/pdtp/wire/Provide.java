package org.pdtp.wire;

import org.pdtp.Resource;

public class Provide {
  public Provide(Resource r) {
    this.range = r.getRange();
    this.url = r.getUrl();
  }
  
  public Range range;
  public String url;
}
