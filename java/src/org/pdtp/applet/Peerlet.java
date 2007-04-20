package org.pdtp.applet;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.Channels;
import java.util.Properties;
import java.util.Random;

import org.pdtp.MemoryCache;
import org.pdtp.NanoHTTPD;
import org.pdtp.Network;
import org.pdtp.wire.TellInfo;

public class Peerlet {   
  private static final long serialVersionUID = 5379473051407182801L;

  private static final int MIN_PORT = 2048;
  private static final int MAX_PORT = 10000;
  private static final int MAX_ATTEMPTS = 100;
  
  public static Peerlet getPeerlet(String server, int serverPort,
                                   long peerTimeout) {
    if(instance != null) return instance;
    
    instance = new Peerlet(server, serverPort, peerTimeout);
    return instance;
  }
  
  public static void killPeerlet() {
    if(instance != null) {
      instance.stop();
      instance = null;
    }
  }
  
  public Peerlet(String server, int serverPort,      
                 long peerTimeout) {
    this.server = server;
    this.serverPort = serverPort;
    this.timeout = peerTimeout;     
  }

  public boolean isRunning() {
    return running;
  }
  
  public void start() {
    Random portGen = new Random();
    
    boolean initializedNetwork = false;
    int attempt = 0;    
    while(!initializedNetwork && ++attempt <= MAX_ATTEMPTS) {
      sharePort = MIN_PORT + portGen.nextInt(MAX_PORT - MIN_PORT);
      
      try {
        net = new Network(server, serverPort, sharePort, new MemoryCache());
        initializedNetwork = true;
      } catch(IOException e) {
        if(attempt == MAX_ATTEMPTS) {
          System.err.println("Couldn't initialize connection to server. Tried "
              + MAX_ATTEMPTS + " times.");        
          e.printStackTrace();
        }
      }
    }
    
    if(!initializedNetwork)
      return;
    
    boolean initializedLocalServe = false;
    attempt = 0;    
    while(!initializedLocalServe && ++attempt <= MAX_ATTEMPTS) {
      localHttpPort = MIN_PORT + portGen.nextInt(MAX_PORT - MIN_PORT);
      
      try {
        localServer = new PeerletHTTP(localHttpPort);
        initializedLocalServe = true;
        running = true;
      } catch(IOException e) {
        if(attempt == MAX_ATTEMPTS) {
          System.err.println("Couldn't initialize local HTTP. Tried "
              + MAX_ATTEMPTS + " times.");        
          e.printStackTrace();
        }      
      }
    }    
  }
  
  public void stop() {
    running = false;
  }  
  
  public int getLocalHttpPort() {
    return this.localHttpPort;
  }
  
  public int getSharePort() {
    return this.sharePort;
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
  
  private boolean running;
  private PeerletHTTP localServer;
  private long timeout;
  private Network net;  
  private String server;
  private int serverPort;
  private int sharePort;
  private int localHttpPort;
  
  private static Peerlet instance;
}
