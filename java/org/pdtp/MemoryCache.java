package org.pdtp;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.Pipe;
import java.nio.channels.ReadableByteChannel;
import java.nio.channels.WritableByteChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.SortedSet;
import java.util.TreeSet;

import org.pdtp.wire.Range;

public class MemoryCache implements Library {
  public MemoryCache() {
    catalogue = new HashMap<String, SortedSet<MemoryCacheElement>>();
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
          .less(catalogue.get(resource.getUrl()));
    
    return missing;
  }
  
  public ReadableByteChannel getChannel(Resource resource, boolean blocking)
      throws IOException {
    if(!blocking && !contains(resource))
      return null;

    CacheReader r = new CacheReader(resource);
    r.start();
    return r.getChannel();    
  }

  public synchronized void write(Resource resource, ByteBuffer buffer) {
    if(!catalogue.containsKey(resource.getUrl()))
      catalogue.put(resource.getUrl(),
          new TreeSet<MemoryCacheElement>()); 
    
    Range range = resource.getRange();
    
    Set<Range> remainder = range.less(catalogue.get(resource.getUrl()));
    if(!remainder.isEmpty() &&
        remainder.iterator().next().equals(range)) {
      MemoryCacheElement m = new MemoryCacheElement(range, buffer);
      catalogue.get(resource.getUrl()).add(m);
      notifyAll();
      return;
    }
    
    for(MemoryCacheElement e : catalogue.get(resource.getUrl())) {
      if(e.intersects(range)) {
        Range i = range.intersection(e);        
        
        synchronized(e.buffer) {
          //e.buffer.position((int) (i.min() - e.min()));
          buffer.position((int) (i.min() - resource.getRange().min()));
          //e.buffer.put(buffer);
          e.buffer.put(buffer.array(),
              (int) (i.min() - resource.getRange().min()),
              e.buffer.remaining());
        }
      }
    }
    
    for(Range r : remainder) {
      ByteBuffer buf = allocate(r.size());
      buffer.position((int) r.min());
      buf.put(buffer);
      MemoryCacheElement m = new MemoryCacheElement(r, buf);
      catalogue.get(resource.getUrl()).add(m);
    }
    
    notifyAll();
  }
 
  private class MemoryCacheElement extends Range {
    public MemoryCacheElement(Range r, ByteBuffer b) {
      super(r.min, r.max);
      this.buffer = b;
    }
    
    public ByteBuffer buffer;
  }
  
  private class CacheReader extends Thread {
    protected Resource resource;
    protected Pipe pipe;
    
    public CacheReader(Resource res) throws IOException {
      this.resource = res;
      this.pipe = Pipe.open();
    }

    public ReadableByteChannel getChannel() {
      return pipe.source();
    }
    
    @Override
    public void run() {
      Range needed = resource.getRange();
      if(needed == null)
        needed = new Range(0, Long.MAX_VALUE);

      WritableByteChannel out = pipe.sink();
      
      while(!catalogue.containsKey(resource.getUrl())) { }
      
      try {
        while(!needed.isEmpty()) {
          for(MemoryCacheElement e : catalogue.get(resource.getUrl())) {
            if(e.contains(needed.min())) {
              Range i = needed.intersection(e);

              ByteBuffer buf = allocate(i.size());
              synchronized(e.buffer) {
                buf.put(e.buffer.array(),
                        (int) (i.min() - e.min()),
                        buf.remaining());
                buf.rewind();
              }

              out.write(buf);            
              needed = needed.minus(e);
            }
          }
          
          if(!needed.isEmpty())
            waitForUpdate();
        }
        
        out.close();
      } catch (IOException ex) {
        ex.printStackTrace();
      }
    }
  }

  public synchronized void waitForUpdate() {
    boolean interrupted = true;
    while(!interrupted) {
      try {
        wait();
      } catch (InterruptedException e) { }
    }
  }
  
  private final Map<String, SortedSet<MemoryCacheElement>> catalogue;
}
