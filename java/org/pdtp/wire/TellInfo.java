package org.pdtp.wire;

public class TellInfo {
  public String url;
  public long size;
  public long chunkSize;
  public boolean streamable;
  
  public long getChunkSize() {
    return chunkSize;
  }

  public long getSize() {
    return size;
  }

  public boolean isStreamable() {
    return streamable;
  }

  public String getUrl() {
    return url;
  }

  @Override
  public String toString() {
    return "TELL_INFO " +
          "url=\"" + url + "\" " +
          "size=" + size + " " +
          "chunkSize=" + chunkSize + " " +
          "streamable=" + streamable;
  }
}
