package org.pdtp.applet;

import java.applet.Applet;

public class PDTPApplet extends Applet {
  private static final long serialVersionUID = -7844878798366445725L;
  
  @Override
  public void init() {
    super.init();
    
    String server = getParameter("server");
    int serverPort = Integer.parseInt(getParameter("server-port"));
    int sharePort = Integer.parseInt(getParameter("share-port"));
    int localHttpPort = Integer.parseInt(getParameter("local-http-port"));
    long peerTimeout = Long.parseLong(getParameter("base-url-timeout"));

    peerlet = Peerlet.getPeerlet(server, serverPort, sharePort,
        localHttpPort, peerTimeout);
  }

  public int getLocalHttpPort() {
    return peerlet.getLocalHttpPort();
  }
  
  @Override
  public void start() {
    super.start();
    peerlet.start();
  }

  @Override
  public void stop() {
    peerlet.stop();
    super.stop();
  }

  private Peerlet peerlet;
}
