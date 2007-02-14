package org.pdtp;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.net.InetAddress;
import java.nio.channels.ByteChannel;
import java.util.Map;

import org.pdtp.wire.AskInfo;
import org.pdtp.wire.Request;
import org.pdtp.wire.TellInfo;

public class Network {
  public Network(String host, int port, Library cache) throws IOException {    
    this.cache = cache;
    
    InetAddress addr = InetAddress.getByName(host);    
    this.link = new Link(new SocketEndpoint(new JSONSerializer("org.pdtp.wire"), addr, port));
    //link.addTransferListener(this);
    this.link.start();
  }
      
  protected ByteChannel getChannel(Object address) {
    try {
      File f = File.createTempFile(address.toString(), null);
      FileInputStream F = new FileInputStream(f);
      return F.getChannel();
    } catch (IOException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
      return null;
    }
  }
  
  public TellInfo getInfo(String url) throws IOException {
    if(!metadataCache.containsKey(url)) {
      TellInfo i = link.blockingRequest(new AskInfo(url), new InfoRequest(url));
      metadataCache.put(url, i);
    }
    
    return metadataCache.get(url);    
  }
  
  public InputStream get(String url) throws IOException {
    Transfer t = new Transfer(url, true);
    t.start();
    return t.getInputStream();
  }
  
  private class Transfer extends Thread {
    public Transfer(String url, boolean download) {
      this.url = url;
      this.download = download;
    }
    
    @Override
    public void run() {
      try {
        if(!this.download && !metadataCache.containsKey(url))
          return;
        
        this.fileInfo = getInfo(url);
        
        this.numChunks = fileInfo.size / fileInfo.chunkSize;
        numChunks += (fileInfo.size % fileInfo.chunkSize == 0) ? 0 : 1;
                
        sink = new PipedInputStream();
        PipedOutputStream out = new PipedOutputStream(sink);
        
        for(int i = 0; i != numChunks; ++i) {
          Resource chunk = new Resource(url, i);
          if(cache.containsKey(chunk)) {
            DataChunk data = cache.get(chunk);

            out.write(data.getSource().array(),
                      (int) data.getOffset(),
                      (int) data.getLength());
          } else {
            if(download) {
              link.send(new Request(chunk));
              cache.getBlocking(chunk);
              --i;
            } else {
              break;
            }
          }
        }
        
        out.close();
        
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    
    public InputStream getInputStream() {
      return sink;
    }
    
    private PipedInputStream sink;
    private final String url;
    private TellInfo fileInfo;
    private long numChunks;
    private boolean download;    
  }
  
  private Map<String, TellInfo> metadataCache;
  private Library cache;
  private Link link;
}
