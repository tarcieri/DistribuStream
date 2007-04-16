package org.pdtp;

import static org.pdtp.Logger.info;
import static org.pdtp.Logger.warn;

import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.Vector;

import org.pdtp.wire.AskInfo;
import org.pdtp.wire.Completed;
import org.pdtp.wire.Provide;
import org.pdtp.wire.Range;
import org.pdtp.wire.Request;
import org.pdtp.wire.TellInfo;
import org.pdtp.wire.Transfer;

/**
 * The Network class provides a convenient interface for applications to
 * connect to PDTP networks.
 * 
 */
public class Network implements ResourceHandler {
  /**
   * Connects to a peer network coordinated by the specified server,
   * serving local data on the specified port. 
   * 
   * @param host the coordinating server hostname
   * @param port the coordinating server port
   * @param peerPort the local port to share data on
   * @param cache a library that backs data downloaded by the library (required)
   * @see Library
   * @throws IOException
   */
  public Network(String host, int port, int peerPort, Library cache) throws IOException {    
    this.cache = cache;
    this.metadataCache = new HashMap<String, TellInfo>();
    
    this.serverHost = host;    
    
    InetAddress addr = InetAddress.getByName(host);
    this.id = UUID.randomUUID().toString().substring(0, 5);    
    this.link = new Link(new SocketEndpoint
        (new JSONSerializer("org.pdtp.wire"), addr, port), peerPort, id);
    link.setResourceHandler(this);
    this.link.setDaemon(true);
    this.link.start();
  }
  
  /**
   * Gets information about the specified URL. This function
   * blocks until data is provided.
   * 
   * This is equivalent to getInfo(url, 0).
   * 
   * @param url the url to query
   * @return a tellinfo data structure with information about
   *         the url
   * @see TellInfo
   * @throws IOException
   */
  public TellInfo getInfo(String url) throws IOException {
    return getInfo(url, 0);
  }
  
  /**
   * Gets information about the specified URL. This function
   * blocks until data is provided, or until the specified timeout
   * is reached. A timeout of zero blocks forever.
   * 
   * @param url the url to query
   * @param timeout the query timeout
   * @return timeout a tellinfo data structure with information about
   *         the url
   * @throws IOException
   */
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
  
  /**
   * As getInfo, but data is returned only if it has been cached
   * this session.
   *  
   * @param url the url to query
   * @returns information about the url, if cached. null otherwise.
   */
  public TellInfo getInfoCached(String url) {
    return metadataCache.get(url);
  }
  
  /**
   * Returns a channel providing the specified data, but only
   * if the data is already in the cache. Returns null otherwise.
   * 
   * @param res the resource to return
   * @return a channel providing data for resource, or null.
   */
  public ReadableByteChannel getCached(Resource res) throws IOException {
    return cache.getChannel(res, false);
  }
  
  /**
   * Returns a channel providing the specified URL. All network
   * details are handled by lower layers.
   * 
   * This is equivalent to calling get(url, 0).
   * 
   * @param url the requested URL
   * @return URL data provided by the peer network, or the source URL.
   * @throws IOException
   */
  public ReadableByteChannel get(String url) throws IOException {
    Resource r = new Resource(url, null);
    return get(r);
  }
  
  /**
   * Returns a channel providing the specified URL. All network
   * details are handled by lower layers.
   * 
   * Timeout specifies, broadly, how long to wait for peers before
   * giving up and downloading the original URL.
   * 
   * @param url the requested URL
   * @param timeout a network timeout hint
   * @return
   * @throws IOException
   */
  public ReadableByteChannel get(String url, long timeout) throws IOException {
    Resource r = new Resource(url, null);
    return get(r, timeout);
  }
  
  /**
   * Returns a channel providing the specified URL. All network
   * details are handled by lower layers.
   * 
   * 
   * @param res the requested resource
   * @return
   * @throws IOException
   */
  public ReadableByteChannel get(Resource res) throws IOException {
    return get(res, 0);
  }
  
  /**
   * Returns a channel providing the specified URL. All network
   * details are handled by lower layers.
   * 
   * Timeout specifies, broadly, how long to wait for peers before
   * giving up and downloading the original URL.
   * 
   * @param res the requested resource
   * @param timeout network timeout hint
   * @return
   * @throws IOException
   */
  public ReadableByteChannel get(Resource res, long timeout) throws IOException {
    TellInfo info = getInfo(res.getUrl(), timeout);
    
    Requester req = new Requester(res, timeout);
    req.start();        
    
    if(info != null && info.size != 0) {
      res = new Resource(res.getUrl(), new Range(0, info.size));
    }      
    
    return cache.getChannel(res, true);  
  }    
  
  /**
   * Equivalent to Channels.newInputStream(get(url)).
   * 
   * @param url the requested URL.
   * @return an InputStream providing the data from url off the
   *         peer network.
   * @throws IOException
   */
  public InputStream getStream(String url) throws IOException {
    Resource r = new Resource(url, null);
    return getStream(r);
  }
  
  /**
   * Equivalent to Channels.newInputStream(get(url, timeout)).
   * 
   * @param url the requested URL.
   * @param timeout network timeout hint
   * @return an InputStream providing the data from url off the
   *         peer network.
   * @throws IOException
   */
  public InputStream getStream(String url, long timeout) throws IOException {
    Resource r = new Resource(url, null);
    return getStream(r, timeout);
  }
  
  /**
   * Equivalent to Channels.newInputStream(get(res)).
   * 
   * @param res the requested resource
   * @return an InputStream providing the data from url off the
   *         peer network.
   * @throws IOException
   */
  public InputStream getStream(Resource res) throws IOException {
    return getStream(res, 0);
  }
  
  /**
   * Equivalent to Channels.newInputStream(get(res)).
   * 
   * @param res the requested resource
   * @return an InputStream providing the data from url off the
   *         peer network.
   * @throws IOException
   */
  public InputStream getStream(Resource res, long timeout) throws IOException {    
    return Channels.newInputStream(get(res, timeout));
  }
  
  /**
   * Starts the specified transfer. 
   * 
   * @param t the transfer to initiate
   */
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
      info("Told to " + t.method + " " + r + " at " + u);
      
      if(!cache.contains(r)) {
        Fetcher f = new Fetcher(r, u, src.getHost()
            + (src.getPort() > 0
                && src.getPort() != src.getDefaultPort()
                ? ":" + src.getPort()
                : ""), t.peerId);
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

  /**
   * Indicates that new data has been received from the peer network.
   * 
   * This can also be called by clients or libraries to indicate changes
   * in the data they have available.
   * 
   * @param b the raw data
   * @param r the resource received
   * @param host the host from which the data came
   * @param port the port the connection occurred on
   * @param id the id of the providing peer
   */
  public void postComplete(ByteBuffer b, Resource r, String host, int port, String id) {
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
        
        String bstr = Integer.toHexString(i);
        hashStr += bstr.length() == 2 ? bstr : "0" + bstr; 
      }
      
      info(r + " hash=" + hashStr);
      
      Completed tc = new Completed(r.getUrl(), host, port, hashStr, r.getRange(), id);
      info("*** CHUNK TRANSFER SUCCESS: " + tc);      
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
  
  /**
   * Injects the specified file information into the metadata cache.
   * 
   * This is used primarily by Link. Consumers should not use.
   */
  public void infoReceived(TellInfo info) {
    synchronized(metadataCache) {
      if(info.mimeType == null || "".equals(info.mimeType))
        info.mimeType = "application/octet-stream";
      
      metadataCache.put(info.url, info);
      metadataCache.notifyAll();
    }
  }

  public ByteBuffer postRequested(Resource r) {
    // TODO Auto-generated method stub
    return null;
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
          
          info("Getting info...");
          TellInfo info = getInfo(resource.getUrl(), timeout);
          if(info != null) {
             requestRange = new Range(0, info.size);
          } else {
            info("NO INFO, Raw request.");
            makeRawRequest(resource);
            return;
          }
        }
        
        if(requestRange == null || requestRange.isEmpty()) {
          link.send(new Request(new Resource(resource.getUrl(), null)));
        } else {        
          info("Request Range (" + requestRange + ")");
          Set<Range> missing = cache.missing(new Resource(resource.getUrl(), requestRange));
          for(Range m : missing) {
            info("  Missing (" + m + ")");
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
            info("Partial time out, raw request.");
            makeRawRequest(res);
          }
        } else {
          info("Timed out, raw request.");
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
        t.peerId = "rawurl:" + myurl;
        transferCommand(t);
      } catch (MalformedURLException e) {
        e.printStackTrace();
      }      
    }
  }

  private class Fetcher extends Thread {
    private String vhost;
    private String peerId;
    
    public Fetcher(Resource r, URL base, String vhost, String peerId) {
      this.resource = r;
      this.base = base;
      this.vhost = vhost;
      this.peerId = peerId;
    }
    
    @Override
    public void run() {            
      try {        
        HttpURLConnection conn = (HttpURLConnection) base.openConnection();
        conn.setRequestProperty("Host", vhost);
        conn.setRequestProperty("X-PDTP-Peer-Id", id.toString());
        
        conn.setRequestMethod("GET");
        if(resource.getRange() != null) {          
          conn.setRequestProperty("Range",
              "bytes=" + resource.getRange().min() + "-"
              + (resource.getRange().max() - 1));
        }
        
        info("  <" + Thread.currentThread().getName() + ">  " + conn.getRequestMethod() + " " + conn.getURL().getPath());
        for(Map.Entry<String, List<String>> e 
            : conn.getRequestProperties().entrySet()) {
          info("  <" + Thread.currentThread().getName() + ">  " + e.getKey() + ": ");
          for(String v : e.getValue()) {
            info(v + " ");
          }
          info("\n");
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
          info("RANGE: " + conn.getHeaderField("Content-Range"));
          actualRange = Range.parseHTTPRange(conn.getHeaderField("Content-Range"));           

          if(actualRange == null) {
            actualRange = resource.getRange();
          }
        } else if(conn.getResponseCode() == HttpURLConnection.HTTP_OK) {
          if(conn.getContentLength() != -1) {
            actualRange = new Range(0, conn.getContentLength());            
          }
        }                
        
        Resource actualResource = null;
        ByteBuffer data = null;
        if(actualRange != null) {
          actualResource = new Resource(resource.getUrl(), actualRange);
          data = cache.allocate(actualRange.size());
        
          while(in.isOpen() && data.hasRemaining()) {
            in.read(data);
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
          
          data = ByteBuffer.wrap(bytes);
          actualRange = new Range(0, bytes.length);
          actualResource = new Resource(resource.getUrl(), actualRange);                    
        }        
        // if(!cache.contains(actualResource))
        postComplete(data, actualResource, base.getHost(),
            base.getPort(), peerId);
        // }

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
      } catch(Throwable e) {
        e.printStackTrace();
        Range failedRange = resource.getRange() != null ? resource.getRange() : new Range(0, 0);
        Completed tc = new Completed(resource.getUrl(),
            base.getHost(), base.getPort(), e.toString(), failedRange, peerId);
        warn("*** CHUNK TRANSFER FAILED: " + tc);        
        try {
          link.send(tc);
        } catch (IOException e1) {
          // TODO Auto-generated catch block
          e1.printStackTrace();
        }
      }
    }
    
    private final URL base;
    private final Resource resource;
  }
  
  private Map<String, TellInfo> metadataCache;
  private Library cache;
  private Link link;    
  private String serverHost;
  private final String id;
}