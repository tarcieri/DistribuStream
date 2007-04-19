package org.pdtp.applet;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.Channels;
import java.util.Properties;

import org.pdtp.MemoryCache;
import org.pdtp.NanoHTTPD;
import org.pdtp.Network;
import org.pdtp.wire.TellInfo;

public class Peerlet {   
  private static final long serialVersionUID = 5379473051407182801L;

  public static Peerlet getPeerlet(String server, int serverPort,
                                   int sharePort, int localHttpPort,
                                   long peerTimeout) {
    if(instance != null) return instance;
    
    return instance = new Peerlet(server, serverPort, sharePort, localHttpPort, peerTimeout);
  }
  
  public static void killPeerlet() {
    if(instance != null) {
      instance.stop();
      instance = null;
    }
  }
  
  public Peerlet(String server, int serverPort,
                 int sharePort, int localHttpPort,
                 long peerTimeout) {
    this.server = server;
    this.serverPort = serverPort;
    this.sharePort = sharePort;
    this.localHttpPort = localHttpPort;
    this.timeout = peerTimeout;     
  }

  public int start() {
    try {
      net = new Network(server, serverPort, sharePort, new MemoryCache());
      localServer = new PeerletHTTP(localHttpPort);
    } catch (IOException e) {
      net = null;
      e.printStackTrace();
    }
    
    return localHttpPort;        
  }
  
  public void stop() {
    
  }  
  
  public int getLocalHttpPort() {
    return this.localHttpPort;
  }
  
  private class PeerletHTTP extends NanoHTTPD {
    public PeerletHTTP(int port) throws IOException {
      super(port);
    }
    
    @Override
    public Response serve(String uri, String method, Properties header, Properties parms) {
      try {
        String url = uri.substring(1);
        InputStream is = null;
        if(timeout != 0)
          is = Channels.newInputStream(net.get(url, timeout));
        else
          is = Channels.newInputStream(net.get(url));
        
        TellInfo inf = net.getInfo(url);
        Response r = new NanoHTTPD.Response(NanoHTTPD.HTTP_NOTFOUND, "text/plain", "Not found.");
        if(inf != null && is != null) {
          r = new NanoHTTPD.Response(NanoHTTPD.HTTP_OK, inf.mimeType, is);
        }
      
        return r;
      } catch(Throwable t) {
        String err = "Internal error:" + t.toString() + "\n\n"; 
        for(StackTraceElement e : t.getStackTrace()) {
          err += e + "\n";
        }
        
        return new Response(NanoHTTPD.HTTP_INTERNALERROR, "text/plain", err);
      }
    }    
  }
  
  private PeerletHTTP localServer;
  private long timeout;
  private Network net;  
  private String server;
  private int serverPort;
  private int sharePort;
  private int localHttpPort;
  
  private static Peerlet instance;
}
