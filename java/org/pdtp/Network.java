package org.pdtp;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
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

public class Network extends Thread {
  public Network(String host, int port, Chunkset cache) throws IOException {
    this.cache = cache;
    this.hashes = new HashMap<Chunk, String>();
    this.transfers = new HashMap<String, Transfer>();
    this.requests = new HashMap<String, Request>();
    
    this.server = InetAddress.getByName(host);
    this.port = port;
    
    this.socket = new Socket(server, port);
    this.in = socket.getInputStream();
    this.out = socket.getOutputStream();
  }
  
  @Override
  public void run() {
    System.out.println("in:" + this.in);
    System.out.println("out:" + this.in);
    
    boolean running = true;
    while(running) {
      String packet = null;
      try {
        packet = readPacket();
      } catch (IOException e) {
        e.printStackTrace();
        running = false;
      }
      
      Map<String, String> packetMap = new HashMap<String, String>();
      JSONObject obj = null;
      try {
        obj = new JSONObject(packet);
      } catch (JSONException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
        running = false;
      }
      
      Iterator i = obj.keys();
      for(Object o = i.next(); i.hasNext(); o = i.next()) {
        try {
          packetMap.put(o.toString(), obj.get(o.toString()).toString());
        } catch (JSONException e) {
          // TODO Auto-generated catch block
          e.printStackTrace();
        }
      }

      this.dispatch(packetMap, null);
    }
  }
  
  public String readPacket() throws IOException {
    String str = "";
    
    char c = (char) in.read();
    while(c != '{') c = (char) in.read();
    str += c;
    int balance = 1;
    while(balance != 0) {
      c = (char) in.read();
      if(c == '{') ++balance;
      if(c == '}') --balance;
      str += c;
    }
    
    return str;
  }
  
  public void provide(String url, ByteBuffer data) throws IOException, JSONException {   
    String provideText = new JSONStringer()
      .object()
        .key("url")
        .value(url)
        .object()
          .key("min")
          .value(0)
          .key("max")
          .value(1)
        .endObject()
      .endObject()
      .toString();
    
    byte[] provideBytes = provideText.getBytes();
    out.write(provideBytes);
  }
  
  public Map<String, String> getInfo(String url) throws JSONException, IOException {
    System.out.println("getInfo()");
    String requestText = new JSONStringer()
      .object()
        .key("type")
        .value("ask_info")
        .key("url")
        .value(url)
      .endObject()
      .toString() + "\n";
    System.out.println(requestText);
    out.write(requestText.getBytes());
    out.flush();
    
    Request<Map<String, String>> r = new Request();
    requests.put(url, r);
    Map<String, String> result = r.block();
    System.out.println("result:" + result);
    return result;
  }
  
  public OutputStream request(String url) throws IOException, JSONException {
    // TODO: Write code here.
    
    //Map<String, String> request = new HashMap<String, String>();
    //request.put("url", url);
    return null;
  }
  
  public void dispatch(Map<String, String> headers,
                       ByteChannel content) {    
    if(headers.containsKey("type")) {
      if(headers.get("type").equalsIgnoreCase("tellinfo")) {
        Request<Map<String, String>> r = requests.get(headers.get("url"));
        if(r != null) {
          r.transition(headers);
        }
      }
      
      if(headers.get("type").equalsIgnoreCase("transfer")) {
        Chunk c = new Chunk(headers.get("url"),
            Long.parseLong(headers.get("id")));
        Transfer t = new Transfer
              (c, headers.get("from"),
               headers.get("direction").equalsIgnoreCase("out") ?
               Transfer.Direction.OUT : Transfer.Direction.IN);
        t.start();
        transfers.put(t.toString(), t);
      }
      
      if(headers.get("type").equalsIgnoreCase("tellverify")) {
        Chunk c = new Chunk(headers.get("url"),
            Long.parseLong(headers.get("id")));
        Transfer t = new Transfer
              (c, headers.get("from"),
               headers.get("direction").equalsIgnoreCase("out") ?
               Transfer.Direction.OUT : Transfer.Direction.IN);
        if(!transfers.containsKey(t.toString()))
          transfers.put(t.toString(), t);
        
        t = transfers.get(t.toString());
        t.transition("verified");
      }

      if(headers.get("type").equalsIgnoreCase("tellhash")) {
        Chunk c = new Chunk(headers.get("url"),
            Long.parseLong(headers.get("id")));
        hashes.put(c, headers.get("hash"));
      }

      if(headers.get("type").equalsIgnoreCase("give")) {
        Chunk c = new Chunk(headers.get("url"),
            Long.parseLong(headers.get("id")));
        Transfer t = new Transfer
              (c, headers.get("from"),
               headers.get("direction").equalsIgnoreCase("out") ?
               Transfer.Direction.OUT : Transfer.Direction.IN);
        t.start();
        transfers.put(t.toString(), t);  
      }
    }
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
  
  protected void toServer(Map<String, String> headers) {
    try {
      JSONWriter transferText = new JSONStringer().object();
    
      for(Map.Entry<String, String> entry : headers.entrySet()) {
        transferText.key(entry.getKey());
        transferText.value(entry.getValue());
      }
    
      byte[] bytes = transferText.toString().getBytes();
      out.write(bytes);
    } catch(JSONException e) {
      throw new RuntimeException(e);
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }
  
  private void askVerify(Transfer t) {
    Map<String, String> headers = new HashMap<String, String>();
    headers.put("url", t.getChunk().getUrl());
    headers.put("id", Long.toString(t.getChunk().getChunkID()));
    headers.put("direction",
        t.getDirection() == Transfer.Direction.IN ? "in" : "out");
    toServer(headers);
  }

  private void askHash(Chunk c) {
    Map<String, String> headers = new HashMap<String, String>();
    headers.put("url", c.getUrl());    
    headers.put("id", Long.toString(c.getChunkID()));
    toServer(headers);
  }

  private final Map<Chunk, String> hashes;
  private final Map<String, Transfer> transfers;
  private final Map<String, Request> requests;
  private Chunkset cache;
  
  private final InetAddress server;  

  // 6086
  private final int port;
  private Socket socket;
  private InputStream in;
  private OutputStream out;
}
