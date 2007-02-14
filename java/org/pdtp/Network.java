package org.pdtp;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.net.InetAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.channels.ByteChannel;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONStringer;
import org.json.JSONWriter;
import org.pdtp.wire.AskInfo;
import org.pdtp.wire.Request;
import org.pdtp.wire.TellInfo;

public class Network {
  public Network(String host, int port, Chunkset cache) throws IOException {    
    this.cache = cache;
    
    InetAddress addr = InetAddress.getByName(host);    
    this.link = new Link(new SocketEndpoint(new JSONSerializer("org.pdtp.wire"), addr, port)); 
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
    return link.blockingRequest(new AskInfo(url), new InfoRequest(url));
  }
  
  public InputStream get(String url) throws IOException {
    Transfer t = new Transfer(url);
    t.start();
    return t.getInputStream();
  }
  
  public void getChunk(Chunk chunk) throws IOException {
    link.blockingRequest(new Request(chunk),
        new TransferBlocker(chunk, link));
    
  }
  
  private class Transfer extends Thread {
    public Transfer(String url) {
      this.url = url;
    }
    
    @Override
    public void run() {
      try {
        this.fileInfo = getInfo(url);
        
        this.numChunks = fileInfo.size / fileInfo.chunkSize;
        numChunks += (fileInfo.size % fileInfo.chunkSize == 0) ? 0 : 1;
                
        sink = new PipedInputStream();
        PipedOutputStream out = new PipedOutputStream(sink);
        
        for(int i = 0; i != numChunks; ++i) {
          Chunk chunk = new Chunk(url, i);
          if(cache.containsKey(chunk)) {
            DataChunk data = cache.get(chunk);

            out.write(data.getSource().array(),
                      (int) data.getOffset(),
                      (int) data.getLength());
          } else {
            getChunk(chunk);
            --i;
          }
        }
        
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
  }
  
  private Chunkset cache;
  private Link link;
}
