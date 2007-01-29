package org.pdtp;

import java.nio.ByteBuffer;

public class DataChunk {
  public DataChunk(final long offset, final long length, final ByteBuffer source) {
    super();
    this.offset = offset;
    this.length = length;
    this.source = source;
  }
  
  public long getLength() {
    return length;
  }
  
  public long getOffset() {
    return offset;
  }
  
  public ByteBuffer getSource() {
    return source;
  }
  
  private final long offset;
  private final long length;
  private final ByteBuffer source;
}
