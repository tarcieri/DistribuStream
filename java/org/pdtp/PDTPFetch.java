package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;

public class PDTPFetch {
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
