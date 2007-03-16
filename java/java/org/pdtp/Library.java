package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;
import java.util.Set;

import org.pdtp.wire.Range;

public interface Library {
  public boolean contains(Resource resource);
  public Set<Range> missing(Resource resource);  
  public ByteBuffer allocate(long size);
  public void write(Resource resource, ByteBuffer buffer);
  
  public ReadableByteChannel getChannel(Resource resource, boolean blocking) throws IOException;
}
