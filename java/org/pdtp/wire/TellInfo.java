package org.pdtp.wire;

public class TellInfo {
  public String url;
  public long size;
  public long chunkSize;
  public boolean streamable;
  
  @Override
  public String toString() {
    return "TELL_INFO " +
          "url=\"" + url + "\" " +
          "size=" + size + " " +
          "chunkSize=" + chunkSize + " " +
          "streamable=" + streamable;
  }
}
