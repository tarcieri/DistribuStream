package org.pdtp.wire;

public class ClientInfo {
  public ClientInfo(String id, int port) {
    this.clientId = id;
    this.listenPort = port; 
  }
  
  public String clientId;
  public int listenPort;
}
