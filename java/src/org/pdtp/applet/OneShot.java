package org.pdtp.applet;

import static org.pdtp.Logger.info;

import java.applet.Applet;
import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.Properties;

import netscape.javascript.JSObject;

import org.pdtp.LogWriter;
import org.pdtp.Logger;
import org.pdtp.MemoryCache;
import org.pdtp.NanoHTTPD;
import org.pdtp.Network;
import org.pdtp.wire.TellInfo;

import org.pdtp.Logger.Level;

public class OneShot extends Applet {
  private static final long serialVersionUID = -7844878798366445725L;

  private Network net;
  private AppletHTTP localServer;
  private int localHttpPort;  
  private int timeout;
  
  private class AppletLogWriter implements LogWriter {
    private final JSObject window;
    
    private AppletLogWriter(JSObject window) {
      this.window = window;
    }
    
    public void log(Level level, Object message) {
      if(message != null && level != null) {
        window.call("pdtp_log", new Object[] { level.toString(), message.toString() });        
      }
    }
  }
  
  private class AppletHTTP extends NanoHTTPD {
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

    public AppletHTTP(int port) throws IOException {
      super(port);
    }
    
  }
  
  @Override
  public void init() {
    super.init();
    
    String server = getParameter("server");
    int serverPort = Integer.parseInt(getParameter("server-port"));
    int sharePort = Integer.parseInt(getParameter("share-port"));
    localHttpPort = Integer.parseInt(getParameter("local-http-port"));
    timeout = Integer.parseInt(getParameter("base-url-timeout"));
    
    info("Local HTTP port set to " + localHttpPort);
    
    try {
      net = new Network(server, serverPort, sharePort, new MemoryCache());
    } catch (IOException e) {
      net = null;
      e.printStackTrace();
    }
    
    JSObject win = JSObject.getWindow(this);
    Logger.setLogWriter(new AppletLogWriter(win));
    info("Initialized.");
  }

  @Override
  public void start() {
    try {
      info("Starting server on " + localHttpPort);
      localServer = new AppletHTTP(localHttpPort);
      info("Server started.");
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  @Override
  public void stop() {
    super.stop();
  }

  public static void main(String[] args) throws IOException {
    if(args.length != 4) {
      System.err.println("PDTPFetch <url> <server> <serverport> <shareport>");
    } else {
      Network N = new Network(args[1], Integer.parseInt(args[2]),
          Integer.parseInt(args[3]), new MemoryCache());
      ReadableByteChannel c = N.get(args[0], 1000);
      InputStream in = Channels.newInputStream(c);

      int b = in.read();
      while(b != -1) {
        System.out.write(b);
        b = in.read();
      }
    }
  }
}
