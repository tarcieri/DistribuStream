package org.pdtp.applet;

import java.applet.Applet;

public class PDTPApplet extends Applet {
  private static final long serialVersionUID = -7844878798366445725L;
  
  @Override
  public void init() {
    super.init();
    
    String server = getParameter("server");
    int serverPort = Integer.parseInt(getParameter("server-port"));
    long peerTimeout = Long.parseLong(getParameter("base-url-timeout"));

    peerlet = Peerlet.getPeerlet(server, serverPort, peerTimeout);
  }

  public int getLocalHttpPort() {
    return peerlet.getLocalHttpPort();
  }

  public int getSharePort() {
    return peerlet.getSharePort();
  }
  
  @Override
  public void start() {
    super.start();
    if(!peerlet.isRunning())
      peerlet.start();    
  }

  @Override
  public void stop() {
    super.stop();
  }

  private Peerlet peerlet;
}
