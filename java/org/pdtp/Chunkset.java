package org.pdtp;

import java.util.Map;

public interface Chunkset extends Map<Chunk, DataChunk> {
  public DataChunk create(Chunk c, long length);
}
