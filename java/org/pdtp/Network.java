package org.pdtp;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.channels.ByteChannel;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.pdtp.wire.AskInfo;
import org.pdtp.wire.Provide;
import org.pdtp.wire.Range;
import org.pdtp.wire.Request;
import org.pdtp.wire.TellInfo;
import org.pdtp.wire.Transfer;
import org.pdtp.wire.Completed;

public class Network implements ResourceHandler {
  public Network(String host, int port, int peerPort, Library cache) throws IOException {    
    this.cache = cache;
    this.metadataCache = new HashMap<String, TellInfo>();
    
    this.serverHost = host;
    
    InetAddress addr = InetAddress.getByName(host);    
    this.link = new Link(new SocketEndpoint
        (new JSONSerializer("org.pdtp.wire"), addr, port), peerPort);
    link.setResourceHandler(this);
    this.link.setDaemon(true);
    this.link.start();
  }
  
  public TellInfo getInfo(String url) throws IOException {
    return getInfo(url, 0);
  }
  
  public TellInfo getInfo(String url, long timeout) throws IOException {
    TellInfo info = null;
    synchronized(metadataCache) {
      if(!metadataCache.containsKey(url)) {
        link.send(new AskInfo(url));
      
        boolean loop = true;
        while(loop) {
          try {
            metadataCache.wait(timeout);
            loop = !metadataCache.containsKey(url) && timeout == 0;
          } catch (InterruptedException e) { }
        }
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
    TellInfo info = getInfo(res.getUrl(), timeout);
    
    Requester req = new Requester(res, timeout);
    req.start();        
    
    if(info != null && info.size != 0) {
      res = new Resource(res.getUrl(), new Range(0, info.size));
    }      
    
    return cache.getChannel(res, true);  
  }    
  
  public InputStream getStream(String url) throws IOException {
    Resource r = new Resource(url, null);
    return getStream(r);
  }
  
  public InputStream getStream(String url, long timeout) throws IOException {
    Resource r = new Resource(url, null);
    return getStream(r, timeout);
  }
  
  public InputStream getStream(Resource res) throws IOException {
    return getStream(res, 0);
  }
  
  public InputStream getStream(Resource res, long timeout) throws IOException {    
    return Channels.newInputStream(get(res, timeout));
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
          System.err.println("Getting info...");
          TellInfo info = getInfo(resource.getUrl(), timeout);
          if(info != null) {
             requestRange = new Range(0, info.size);
          } else {
            System.err.println("NO INFO, Raw request.");
            makeRawRequest(resource);
            return;
          }
        }
        
        if(requestRange == null || requestRange.isEmpty()) {
          link.send(new Request(new Resource(resource.getUrl(), null)));
        } else {        
          System.err.println("Request Range (" + requestRange + ")");
          Set<Range> missing = cache.missing(new Resource(resource.getUrl(), requestRange));
          for(Range m : missing) {
            System.err.println("  Missing (" + m + ")");
            link.send(new Request(new Resource(resource.getUrl(), m)));
          }
        }
      } catch(IOException e) {
        e.printStackTrace();                
      }
      
      if(timeout != 0) {
        try {
          Thread.sleep(timeout);
        } catch (InterruptedException e) { }
        
        if(requestRange != null && !requestRange.isEmpty()) {
          Set<Range> missing = cache.missing(new Resource(resource.getUrl(), requestRange));
          for(Range m : missing) {
            Resource res = new Resource(resource.getUrl(), m);
            System.err.println("Partial time out, raw request.");
            makeRawRequest(res);
          }
        } else {
          System.err.println("Timed out, raw request.");
          makeRawRequest(new Resource(resource.getUrl(), null));
        }
      }
    }
    
    public void makeRawRequest(Resource part) {      
      Transfer t = new Transfer();
      try {
        String myurl = part.getUrl();
        if(myurl.startsWith("pdtp")) {
          myurl = myurl.replaceFirst("pdtp", "http");
        }

        URL url = new URL(myurl);
        t.range = part.getRange();
        t.method = "get";
        //t.transferUrl = part.getUrl();        
        t.url = part.getUrl();
        t.host = url.getHost();
        t.port = url.getPort() != -1 ? url.getPort() : url.getDefaultPort();        
        transferCommand(t);
      } catch (MalformedURLException e) {
        e.printStackTrace();
      }      
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

  public void postComplete(ByteBuffer b, Resource r, String host, int port) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      b.rewind();
      digest.update(b);
      byte[] hashBytes = digest.digest();
      String hashStr = "";
      for(byte hb : hashBytes) {
        int i = (int) hb;
        if(i < 0)
          i = 256 + i;
        
        hashStr += Integer.toHexString(i);
      }
      
      System.err.println(r + " hash=" + hashStr);
      
      Completed tc = new Completed(r.getUrl(), host, port, hashStr, r.getRange());
      link.send(tc);
    } catch (NoSuchAlgorithmException e1) {
      e1.printStackTrace();
    } catch (IOException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
        
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
    private String vhost;
    
    public Fetcher(Resource r, URL base, String vhost) {
      this.resource = r;
      this.base = base;
      this.vhost = vhost;
    }
    
    @Override
    public void run() {            
      try {        
        HttpURLConnection conn = (HttpURLConnection) base.openConnection();
        conn.setRequestProperty("Host", vhost);
        
        conn.setRequestMethod("GET");
        if(resource.getRange() != null) {          
          conn.setRequestProperty("Range",
              "bytes=" + resource.getRange().min() + "-"
              + (resource.getRange().max() - 1));
        }
        
        System.err.println("  <" + Thread.currentThread().getName() + ">  " + conn.getRequestMethod() + " " + conn.getURL().getPath());
        for(Map.Entry<String, List<String>> e 
            : conn.getRequestProperties().entrySet()) {
          System.err.print("  <" + Thread.currentThread().getName() + ">  " + e.getKey() + ": ");
          for(String v : e.getValue()) {
            System.err.print(v + " ");
          }
          System.err.print("\n");
        }
        
        conn.connect();
        ReadableByteChannel in = Channels.newChannel(conn.getInputStream());
        
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
        if(conn.getResponseCode() == HttpURLConnection.HTTP_PARTIAL) {
          System.err.println("RANGE: " + conn.getHeaderField("Content-Range"));
          actualRange = Range.parseHTTPRange(conn.getHeaderField("Content-Range"));           

          if(actualRange == null) {
            actualRange = resource.getRange();
          }
        } else if(conn.getResponseCode() == HttpURLConnection.HTTP_OK) {
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
          
            postComplete(buf, actualResource, base.getHost(), base.getPort());
          }
        } else {
          InputStream ins = Channels.newInputStream(in);
          Vector<Byte> byteStream = new Vector<Byte>();
          int b = ins.read();
          while(b != -1) {            
            byteStream.add((byte) b);
            b = ins.read();
          }
          
          byte bytes[] = new byte[byteStream.size()];
          int i = 0;
          for(Byte x : byteStream) {
            bytes[i++] = x.byteValue();
          }
          
          actualRange = new Range(0, bytes.length);
          Resource actualResource = new Resource(resource.getUrl(), actualRange);                    
          
          if(!cache.contains(actualResource)) {
            postComplete(ByteBuffer.wrap(bytes), actualResource, base.getHost(),
                base.getPort());

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
      //URL u = new URL(t.transferUrl);
      
      String myurl = t.url;
      if(myurl.startsWith("pdtp")) {
        myurl = myurl.replaceFirst("pdtp", "http");
      }
      
      String peerHost = t.host;
      InetAddress addr = InetAddress.getByName(peerHost);
      if(addr.isLoopbackAddress()) {
        // Silly server. Loopbacks are for extremely flexible kids.
        peerHost = serverHost;
      }
      
      URL src = new URL(myurl);      
      URL u = new URL("http://" + peerHost + ":" + t.port + src.getPath());            
      
      Resource r = new Resource(t.url, t.range);
      System.err.println("Told to " + t.method + " " + r + " at " + u);
      
      if(!cache.contains(r)) {
        Fetcher f = new Fetcher(r, u, src.getHost()
            + (src.getPort() > 0
                && src.getPort() != src.getDefaultPort()
                ? ":" + src.getPort()
                : ""));
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
}
