package org.pdtp;

import static org.pdtp.Logger.info;
import static org.pdtp.Logger.trace;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.URLDecoder;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.Enumeration;
import java.util.Properties;

import org.pdtp.wire.ClientInfo;
import org.pdtp.wire.Completed;
import org.pdtp.wire.Range;
import org.pdtp.wire.TellInfo;
import org.pdtp.wire.Transfer;

/**
 * The Link class takes an endpoint and handles asynchronous from the
 * endpoint along with incoming HTTP connections.
 */
public class Link extends Thread {
  public Link(Endpoint endpoint, int peerPort, String id) {
    this.endpoint = endpoint;
    this.running = true;
    
    if(peerPort > 0) {
      try {
        this.peerServer = new PeerServer(peerPort);
        send(new ClientInfo(id, peerPort));
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }
  
  @Override
  public void run() {
    while(running) {
      Object packet;
      try {
        packet = endpoint.take();
        dispatch(packet);        
      } catch (IOException e) {
        e.printStackTrace();
        if(!endpoint.isOpen())
          running = false;
      }
    }
  }
  
  /**
   * Dispatch a packet once received.
   * 
   * @param packet
   * @throws IOException
   */
  private synchronized <X> void dispatch(X c) {
    if(handler != null) {
      if(c instanceof TellInfo) {
        TellInfo inf = (TellInfo) c;
        if(inf.size != 0)
          handler.infoReceived(inf);
      } else if(c instanceof Transfer) {
        handler.transferCommand((Transfer) c);
      }
    }
  }   
  
  /**
   * Send an packet to the server.
   * 
   * @param packet
   * @throws IOException
   */
  public void send(Object packet) throws IOException {
    endpoint.send(packet);
  }
  
  /**
   * Set this link's resource handler. The resouce handler is
   * contacted whenever a GET request is made to the peer HTTP
   * server.
   * 
   * @param handler
   */
  public void setResourceHandler(ResourceHandler handler) {
    this.handler = handler;
  }

  private class PeerServer extends NanoHTTPD {
    public PeerServer(int port) throws IOException {
      super(port);
    }

    @Override
    public Response serve( String uri, String method,
        Properties header, Properties parms ) {
      try {
        if("GET".equalsIgnoreCase(method)) {
          // Cut away the leading '/'.      
          uri = uri.substring(1);
          uri = URLDecoder.decode(uri, "utf-8");
          String host = header.getProperty("host");
          
          /* For debugging, print all headers:
          
          Enumeration e = header.propertyNames();
          while ( e.hasMoreElements())
          {
            String value = (String)e.nextElement();
            trace( "  HTTPHDR: '" + value + "' = '" +
                      header.getProperty( value ) + "'" );
          }
          */
          
          if(host == null) {
            trace("Error, dropping: no Host header found (host=" + host + ")");

            return new Response(NanoHTTPD.HTTP_NOTIMPLEMENTED,
                "text/plain", "Host header required.");            
          }
          
          uri = "http://" + host + "/" + uri;
          
          TellInfo info = handler.getInfoCached(uri);          
          Response response = new Response();

          response.addHeader("Content-Type", info != null ? info.mimeType : "application/octet-stream");
          
          Range range = Range.parseHTTPRange(header.getProperty("range"));          
          if(range == null) {
            if(info != null) {
              response.status = NanoHTTPD.HTTP_OK;
              range = new Range(0, info.size);
            }
          } else {
            response.status = "206 Partial Content";
            response.addHeader("Content-Range",
                "bytes " + range.min() + "-" + (range.max() - 1) + "/" + (info != null ? info.size : "*")); 
          }
          
          Resource r = new Resource(uri, range);
          ReadableByteChannel ch = handler.getCached(r);
          if(ch == null) {
            response.status = NanoHTTPD.HTTP_NOTFOUND;
            response.data = new ByteArrayInputStream("Not found.".getBytes());
          } else {
            response.data = Channels.newInputStream(ch);
          }
          
          Range reportedRange = new Range(r.getRange().min(),
                                           r.getRange().max());
          trace("range_header=" + range);
          trace("reportedRange=" + reportedRange);
          String rPeerId = header.getProperty("x-pdtp-peer-id");
          Completed tc = new Completed(r.getUrl(), "was_server", reportedRange, rPeerId);
          info("SCOMPLETE:" + tc);
          send(tc);
          
          return response;
        } else {
          return new Response(NanoHTTPD.HTTP_NOTIMPLEMENTED,
              "text/plain", "Method " + method + "unsupported.");
        }
      } catch(Exception ex) {
        ex.printStackTrace(System.err);
        
        return new Response(NanoHTTPD.HTTP_INTERNALERROR,
            "text/plain", ex.toString());
      }
    }
  }

  private boolean running;
  private Endpoint endpoint;
  private ResourceHandler handler;
  protected PeerServer peerServer;
}
