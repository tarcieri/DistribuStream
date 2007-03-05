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

import static java.util.Collections.synchronizedMap;
import static java.util.Collections.synchronizedSortedSet;

public class MemoryCache implements Library {
  public MemoryCache() {
    catalogue = synchronizedMap(new HashMap<String, SortedSet<MemoryCacheElement>>());
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

    CacheReader r = new CacheReader(resource, this);
    r.start();
    return r.getChannel();    
  }

  public synchronized void write(Resource resource, ByteBuffer buffer) {
    System.err.println(" >>>>>>>>>> WRITE " + resource);
    
    if(!catalogue.containsKey(resource.getUrl()))
      catalogue.put(resource.getUrl(),
          synchronizedSortedSet(new TreeSet<MemoryCacheElement>())); 
    
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
    protected MemoryCache cache;
    
    public CacheReader(Resource res, MemoryCache cache) throws IOException {
      this.resource = res;
      this.pipe = Pipe.open();
      this.cache = cache;
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
      
      synchronized(cache) {      
        while(!catalogue.containsKey(resource.getUrl())) {
          try {
            cache.wait();
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
      
      try {
        while(!needed.isEmpty()) {
          MemoryCacheElement chain[]
            = catalogue.get(resource.getUrl()).toArray(new MemoryCacheElement[0]);
                   
          for(MemoryCacheElement e : chain) {
            System.err.println(">>>>> I NEED " + needed);
            if(e.contains(needed.min())) {
              
              Range i = needed.intersection(e);
              System.err.println("<<<< FOUND " + e + "[" + i + "]");
              
              ByteBuffer buf = allocate(i.size());
              synchronized(e.buffer) {
                buf.put(e.buffer.array(),
                        (int) (i.min() - e.min()),
                        buf.remaining());
                buf.rewind();
              }
              
              //for(int z = 0; z < buf.capacity(); ++z) {
              //  System.err.println(" ==== " + (char) buf.get(z));
              //}
              
              while(buf.remaining() != 0)
                out.write(buf);              
              needed = needed.minus(e);
            }
          }
          
          synchronized(cache) {
            if(!needed.isEmpty()) {
              try {
                System.err.println(">>>>> I NEED " + needed + "::");
                cache.wait();
              } catch (InterruptedException e1) {
                e1.printStackTrace();
              }
            }
          }
        }
        
        out.close();
      } catch (IOException ex) {
        ex.printStackTrace();
      }
    }
  }

  private final Map<String, SortedSet<MemoryCacheElement>> catalogue;
}
