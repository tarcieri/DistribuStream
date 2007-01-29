package org.pdtp;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;

public class MemoryCache
              extends HashMap<Chunk, DataChunk>
              implements Chunkset {
  private static final long serialVersionUID = -2313811475353604384L;

  public MemoryCache() {
    this.cache = new HashMap<Chunk, DataChunk>();
  }
  
  public DataChunk create(Chunk c, long length) {
    ByteBuffer buffer = ByteBuffer.allocate((int) length);
    DataChunk d = new DataChunk(0, length, buffer); 
    cache.put(c, d);
    return d;
  }
  
  private Map<Chunk, DataChunk> cache;
}
