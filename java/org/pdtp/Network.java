package org.pdtp;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.channels.ByteChannel;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.pdtp.wire.AskInfo;
import org.pdtp.wire.Provide;
import org.pdtp.wire.Range;
import org.pdtp.wire.Request;
import org.pdtp.wire.TellInfo;
import org.pdtp.wire.Transfer;

public class Network implements ResourceHandler {
  public Network(String host, int port, Library cache) throws IOException {    
    this.cache = cache;
    this.metadataCache = new HashMap<String, TellInfo>();
    
    this.serverHost = host;
    this.serverPort = port;
    
    InetAddress addr = InetAddress.getByName(host);    
    this.link = new Link(new SocketEndpoint(new JSONSerializer("org.pdtp.wire"), addr, port));
    link.setResourceHandler(this);
    this.link.setDaemon(true);
    this.link.start();
    
    this.cache.setResourceHandler(this);
  }
      
  protected ByteChannel getChannel(Object address) {
    try {
      File f = File.createTempFile(address.toString(), null);
      FileInputStream F = new FileInputStream(f);
      return F.getChannel();
    } catch (IOException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
      return null;
    }
  }    
  
  public TellInfo getInfo(String url) throws IOException {
    return getInfo(url, 0);
  }
  
  public TellInfo getInfo(String url, long timeout) throws IOException {
    System.out.println("Getting info for " + url);
    TellInfo info = null;
    synchronized(metadataCache) {
      if(!metadataCache.containsKey(url)) {
        link.send(new AskInfo(url));
      }
      
      boolean loop = true;
      while(loop) {
        try {
          metadataCache.wait(timeout);
          loop = !metadataCache.containsKey(url) && timeout == 0;
        } catch (InterruptedException e) { }
      }
      info = metadataCache.get(url);
    }

    return info;
  }
  
  public TellInfo getInfoCached(String url) {
    return metadataCache.get(url);
  }
  
  public ReadableByteChannel getCached(Resource res) throws IOException {
    return cache.getChannel(res, false);
  }
  
  public ReadableByteChannel get(String url) throws IOException {
    Resource r = new Resource(url, null);
    return get(r);
  }
  
  public ReadableByteChannel get(String url, long timeout) throws IOException {
    Resource r = new Resource(url, null);
    return get(r, timeout);
  }
  
  public ReadableByteChannel get(Resource res) throws IOException {
    return get(res, 0);
  }
  
  public ReadableByteChannel get(Resource res, long timeout) throws IOException {
    Requester req = new Requester(res, timeout);
    req.start();
    return cache.getChannel(res, true);  
  }    
  
  private class Requester extends Thread {
    private final Resource resource;
    private long timeout;
    
    public Requester(Resource res, long timeout) {
      this.resource = res;
      this.timeout = timeout;
    }
    
    @Override
    public void run() {
      Range requestRange = resource.getRange();
      
      try {       
        if(requestRange == null) {
          TellInfo info = getInfo(resource.getUrl(), timeout);
          if(info != null) {
            requestRange = new Range(0, info.size);
          } else {
            makeRawRequest(resource);
            return;
          }
        }        
        
        System.out.println("Request range=" + requestRange);
        Set<Range> missing = cache.missing(new Resource(resource.getUrl(), requestRange));
        for(Range m : missing) {
          System.out.println("  requesting " + m);
          link.send(new Request(new Resource(resource.getUrl(), m)));
        }
      } catch(IOException e) {
        e.printStackTrace();                
      }

      System.out.println("done with requests");
      
      if(timeout != 0) {
        try {
          Thread.sleep(timeout);
        } catch (InterruptedException e) { }
        
        
        Set<Range> missing = cache.missing(new Resource(resource.getUrl(), requestRange));
        for(Range m : missing) {
          Resource res = new Resource(resource.getUrl(), m);
          makeRawRequest(res);
        }        
      }
    }
    
    public void makeRawRequest(Resource part) {      
      Transfer t = new Transfer();
      t.byteRange = part.getRange();
      t.method = "get";
      t.transferUrl = part.getUrl();
      t.url = part.getUrl();
      transferCommand(t);      
    }
  }
  
  
  private Map<String, TellInfo> metadataCache;
  private Library cache;
  private Link link;
  
  public void infoReceived(TellInfo info) {
    synchronized(metadataCache) {
      metadataCache.put(info.url, info);
      metadataCache.notifyAll();
    }
  }

  public void postComplete(ByteBuffer b, Resource r) {
    // TODO: Notify the server of the successful transfer.
    // TODO: Verify the hash of this segment before writing it.    
    cache.write(r, b);
    
    try {
      link.send(new Provide(r));
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  public ByteBuffer postRequested(Resource r) {
    // TODO Auto-generated method stub
    return null;
  }

  private class Fetcher extends Thread {
    public Fetcher(Resource r, URL base) {
      this.resource = r;
      this.base = base;
    }
    
    @Override
    public void run() {            
      try {        
        //URL url = new URL(base,
        //    URLEncoder.encode(resource.getUrl(), "utf-8"));
        
        HttpURLConnection conn = (HttpURLConnection) base.openConnection();
        
        conn.setRequestMethod("GET");
        if(resource.getRange() != null) {
          conn.setRequestProperty("Range",
              "bytes=" + resource.getRange().min() + "-"
              + resource.getRange().max());
        }
        
        conn.connect();        
        InputStream ins = conn.getInputStream();
        ReadableByteChannel in = Channels.newChannel(conn.getInputStream());
        
        //
        // This is all a bit complicated. We want to find out
        // what fragment of the file we're actually receiving.
        // The code below uses the following methodology:
        //
        // - If the server responded with 206 (Partial content),
        //   it MUST (according to the HTTP standard) include
        //   either a Content-Range header or data multipart/byteranges
        //   Content-Type. Bug: we don't currently support the
        //   latter. If we received a 206, we use the Content-Range
        //   header to discern the returned range.
        //
        // - If the server responded with 200 (OK), we're assuming
        //   it's handing us data from the beginning of the file, so
        //   our range is of the form (0, x). To find x, we use the
        //   Content-Length header.
        //
        // - Finally, if all that fails, we just assume the range we
        //   were called with is correct. Note that this is not a
        //   great assumption, as the server is allowed to return more
        //   or less data than we wanted.
        //
        
        Range actualRange = resource.getRange();
        if(conn.getResponseCode() == conn.HTTP_PARTIAL) {
          actualRange = Range.parseHTTPRange(conn.getHeaderField("Content-Range"));           

          if(actualRange == null) {
            actualRange = resource.getRange();
          }
        } else if(conn.getResponseCode() == conn.HTTP_OK) {
          if(conn.getContentLength() != -1) {
            actualRange = new Range(0, conn.getContentLength());            
          }
        }                
        
        if(actualRange != null) {
          Resource actualResource = new Resource(resource.getUrl(), actualRange);
          if(!cache.contains(actualResource)) {
            ByteBuffer buf = cache.allocate(actualRange.size());
        
            while(in.isOpen() && buf.hasRemaining()) {
              in.read(buf);
            }
          
            postComplete(buf, actualResource);
          
            // Update the mime type and entity size information, possibly.
            TellInfo inf = getInfoCached(resource.getUrl());
            if(inf != null) {
              if("application/octet-stream".equals(inf.mimeType))
                inf.mimeType = conn.getContentType();
            } else {
              inf = new TellInfo();
              inf.chunkSize = 1;
              inf.mimeType = conn.getContentType();
              inf.size = actualResource.getRange().max();
              inf.streamable = false;
              inf.url = actualResource.getUrl();
            }
            infoReceived(inf);
          }
        } else {
          System.out.println("Couldn't figure out how much data we got.");
        }
      } catch (Exception e) {
        e.printStackTrace();        
      }
    }
    
    private final URL base;
    private final Resource resource;
  }
  
  public void transferCommand(Transfer t) {
    try {
      URL u = new URL(t.transferUrl);
      InetAddress addr = InetAddress.getByName(u.getHost());
      if(addr.isLoopbackAddress()) {
        // Silly server. Loopbacks are for extremely flexible kids.
        t.transferUrl = t.transferUrl.replace(u.getHost(), serverHost);
        u = new URL(t.transferUrl);
      }

      Resource r = new Resource(t.url, t.byteRange);
      //System.out.println("Told to " + t.method + " " + r + " at " + u);
      
      if(!cache.contains(r)) {
        Fetcher f = new Fetcher(r, u);
        f.start();
      }
    } catch (MalformedURLException e) {
      // TODO Auto-generated catch block
      //e.printStackTrace();
    } catch (UnknownHostException e) {
      // TODO Auto-generated catch block
      //e.printStackTrace();
    }
  }
  
  private String serverHost;
  private int serverPort;
}
