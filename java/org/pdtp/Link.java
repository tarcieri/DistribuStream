package org.pdtp;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

public class Link extends Thread {
  public Link(Endpoint endpoint) {
    this.endpoint = endpoint;
    this.blockers = new HashSet<Blocker>();
    this.running = true;
  }
  
  @Override
  public void run() {
    while(running) {
      Object packet;
      try {
        packet = endpoint.take();
        dispatch(packet);        
      } catch (IOException e) {
        e.printStackTrace();
        running = false;
      }
    }
  }
  
  private synchronized <X> void dispatch(X c) {
    System.out.println("Dispatching " + c);
    for(Blocker<X> r : blockers) {
      if(r.match(c)) {
        System.out.println("Matched " + r);
        r.transition(c);
      }
    }
  }
  
  public <X> X blockingRequest(Object packet, Blocker<X> request) throws IOException {
    synchronized(this) {
      blockers.add(request);
      if(packet != null) endpoint.send(packet);
    }
    X r = request.block();
    blockers.remove(request);
    return r;    
  }
  
  private boolean running;
  private Endpoint endpoint;
  private Set<Blocker> blockers;
}
