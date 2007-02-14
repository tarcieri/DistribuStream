package org.pdtp;

import org.pdtp.wire.Transfer;

public class TransferBlocker extends Blocker<Object> {
  public TransferBlocker(Resource chunk, Link link) {
    this.chunk = chunk;
    this.link = link;
  }

  @Override
  public boolean match(Object o) {
    if(o instanceof Transfer) {
      Transfer t = (Transfer) o;
      return chunk.getUrl().equals(t.url) &&
             chunk.getChunkID() == t.chunkID;
    }
    
    return false;
  }
  
  private Resource chunk;
  private Link link;  
}
