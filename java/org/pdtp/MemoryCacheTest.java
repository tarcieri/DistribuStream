package org.pdtp;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;

import org.pdtp.wire.Range;

public class MemoryCacheTest {
  public static void main(String[] args) throws IOException {
    MemoryCache cache = new MemoryCache();
    
    Thread t = new Thread(new Producer(cache));
    t.start();
    
    Resource r = new Resource("myurl", null);
    ReadableByteChannel c = cache.getChannel(r, true);

    ByteBuffer buf = ByteBuffer.allocate(512);
    int bytes = c.read(buf);
    
    int cx = 0;
    
    while(bytes != -1) {
      for(int i = 0; i != bytes; ++i) {
        System.out.println(cx++ + ":" + buf.get(i));
      }
      
      buf.rewind();
      bytes = c.read(buf);
    }
  }
  
  public static class Producer implements Runnable {
    private MemoryCache cache;
    public int count;
    
    public Producer(MemoryCache cache) {
      this.cache = cache;
      this.count = 0;
    }
    
    public void run() {
      Resource r[] = new Resource[] {
          new Resource("myurl", new Range(0, 1024)),
          new Resource("myurl", new Range(2048, 3072)),
          new Resource("myurl", new Range(1024, 2048))          
      };
      
      for(int x = 0; x != 3; ++x) {
        ByteBuffer buf = cache.allocate(1024);      
        
        System.err.println("Resource: " + r);
        int last = count + 1024;
        for(; count != last; ++count) {
          buf.put((byte) x);
        }
        
        cache.write(r[x], buf);
      }      
    }    
  }
}
