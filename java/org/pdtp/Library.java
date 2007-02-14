package org.pdtp;

import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;

public interface Library {
  public boolean contains(Resource resource);
  public ByteBuffer allocate(long size);
  public void write(Resource resource, ByteBuffer buffer);
  
  public ReadableByteChannel getChannel(Resource resource);
  public ReadableByteChannel getBlockingChannel(Resource resource);
}
