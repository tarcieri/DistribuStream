package org.pdtp;

import org.pdtp.wire.Range;

public class Resource {
  public Resource(String url, Range range) {
    this.url = url;
    if(range == null)
      this.range = null;
    else
      this.range = new Range(range.min(), range.max());
  }
  
  public Resource(String url, long min, long max) {
    this.url = url;
    this.range = new Range(min, max);
  }
  
  public Range getRange() {
    return this.range;
  }
  
  public String getUrl() {
    return url;
  }
  
  @Override
  public String toString() {
    return url + "::" + range.min() + '-' + range.max();
  }
  
  @Override
  public int hashCode() {
    return this.toString().hashCode();
  }
  
  @Override
  public boolean equals(Object o) {
    return this.toString().equals(o.toString());
  }
  
  private final String url;
  private final Range range;  
}
