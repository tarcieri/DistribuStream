package org.pdtp;

import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import org.pdtp.wire.Range;

public class MemoryCache implements Library {
  public MemoryCache() {
    catalogue = new HashMap<String, Set<MemoryCacheElement>>();
  }
  
  public ByteBuffer allocate(long size) {
    return ByteBuffer.allocate((int) size);
  }

  public boolean contains(Resource resource) {
    return missing(resource).isEmpty();
  }

  public Set<Range> missing(Resource resource) {
    if(!catalogue.containsKey(resource.getUrl())) {
      Set<Range> missing = new TreeSet<Range>();
      missing.add(resource.getRange());
      return missing;
    }
    
    Set<Range> missing = resource.getRange()
          .less(catalogue.get(resource.getUrl()).toArray(new Range[] { }));
    
    return missing;
  }
  
  public ReadableByteChannel getBlockingChannel(Resource resource) {
    // TODO Auto-generated method stub
    return null;
  }

  public ReadableByteChannel getChannel(Resource resource) {
    // TODO Auto-generated method stub
    return null;
  }

  public void write(Resource resource, ByteBuffer buffer) {
    if(!catalogue.containsKey(resource.getUrl()))
      catalogue.put(resource.getUrl(),
          new TreeSet<MemoryCacheElement>()); 
    
    Range newRange = resource.getRange();
    for(MemoryCacheElement e : catalogue.get(resource.getUrl())) {
      if(e.intersects(newRange)) {
        e.buffer.position((int) (newRange.min() - e.min()));
        buffer.position((int) (newRange.min() - resource.getRange().min()));
        e.buffer.put(buffer);
      }
    }
  }
 
  private class MemoryCacheElement extends Range {
    public MemoryCacheElement(Range r, ByteBuffer b) {
      super(r.min, r.max);
      this.buffer = b;
    }
    
    public ByteBuffer buffer;
  }
  
  private final Map<String, Set<MemoryCacheElement>> catalogue;
}
