package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.Socket;

public class SocketEndpoint implements Endpoint {
  public SocketEndpoint(Serializer serializer,
                        InetAddress address, int port) throws IOException {
    this.address = address;
    this.port = port > 0 ? port : 6081;
    
    this.socket = new Socket(address, port);
    this.in = socket.getInputStream();
    this.out = socket.getOutputStream();
    
    this.serializer = serializer;
  }
  
  public synchronized void send(Object packet) throws IOException {
    serializer.write(packet, out);
    out.flush();
  }

  public synchronized Object take() throws IOException {
    return serializer.read(in);
  }
  
  private final Serializer serializer;
  private final Socket socket;
  private final InputStream in;
  private final OutputStream out;
  private final InetAddress address;
  private final int port;
}
