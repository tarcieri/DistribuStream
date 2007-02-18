package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;

public class PDTPFetch {
  public static void main(String[] args) throws IOException {    
    Network N = new Network("catclops.clickcaster.com", 6000, new MemoryCache());
    ReadableByteChannel c = N.get("http://www.feministe.us/", 1000);
    InputStream in = Channels.newInputStream(c);
    System.err.println("Received: ");
    int b = in.read();
    while(b != -1) {
      System.err.write(b);
      b = in.read();
    }
  }
}
