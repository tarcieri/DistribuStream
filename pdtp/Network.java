package org.pdtp;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.channels.ByteChannel;
import java.util.HashMap;
import java.util.Map;

public class Network {
  public Network(Chunkset cache) {
    this.cache = cache;
    this.hashes = new HashMap<Chunk, String>();
    this.transfers = new HashMap<String, Transfer>();
  }
  
  public void dispatch(Map<String, String> headers,
                       ByteChannel content) {
    if(headers.containsKey("type")) {
      if(headers.get("type").equalsIgnoreCase("transfer")) {
        Chunk c = new Chunk(headers.get("url"),
            Long.parseLong(headers.get("id")));
        Transfer t = new Transfer
              (c, headers.get("from"),
               headers.get("direction").equalsIgnoreCase("out") ?
               Transfer.Direction.OUT : Transfer.Direction.IN,
               Transfer.State.VERIFIED);
        t.start();
        transfers.put(t.toString(), t);
      }
      
      if(headers.get("type").equalsIgnoreCase("tellverify")) {
        Chunk c = new Chunk(headers.get("url"),
            Long.parseLong(headers.get("id")));
        Transfer t = new Transfer
              (c, headers.get("from"),
               headers.get("direction").equalsIgnoreCase("out") ?
               Transfer.Direction.OUT : Transfer.Direction.IN,
               Transfer.State.VERIFIED);
        if(!transfers.containsKey(t.toString()))
          transfers.put(t.toString(), t);
        
        t = transfers.get(t.toString());
        t.transition(Transfer.State.VERIFIED);
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
               Transfer.Direction.OUT : Transfer.Direction.IN,
               Transfer.State.UNVERIFIED);
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
    System.out.println(headers);
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

  private Map<Chunk, String> hashes;
  private Map<String, Transfer> transfers;
  private Chunkset cache;
}
