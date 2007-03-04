package org.pdtp.applet;

import java.applet.Applet;
import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;

import org.pdtp.MemoryCache;
import org.pdtp.Network;

public class OneShot extends Applet {
  private static final long serialVersionUID = -7844878798366445725L;

  private Network net;
  private String url;
  
  @Override
  public void init() {
    super.init();
    
    url = getParameter("url");
    String server = getParameter("server");
    int serverPort = Integer.parseInt("server-port");
    int sharePort = Integer.parseInt("share-port");
    
    try {
      net = new Network(server, serverPort, sharePort, new MemoryCache());
    } catch (IOException e) {
      net = null;
      e.printStackTrace();
    }    
  }

  @Override
  public void start() {
    try {
      net.get(url);
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
