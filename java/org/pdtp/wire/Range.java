package org.pdtp.wire;

public class Range {
  public Range() { min = 0; max = 0; }
  
  public Range(long single) {
    min = single; max = single;
  }
  
  public Range(long min, long max) {
    this.min = min; this.max = max;
  }
  
  public long min;
  public long max;
}
