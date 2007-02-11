package org.pdtp;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.SynchronousQueue;

public class Request<T> {
  public Request() {
    this.state = null;
    this.queues = new HashSet<SynchronousQueue<T>>();
  }
  
  public T block() {
    SynchronousQueue<T> mine;
    synchronized(this) {
      mine = new SynchronousQueue<T>();
      queues.add(mine);
    }    
    
    T s = mine.poll();
    
    synchronized(this) {
      queues.remove(mine);
    }
    
    return s;
  }

  protected void transition(T s) {
    if(!this.state.equals(s)) {
      for(SynchronousQueue<T> q : queues) {
        try {
          q.put(s);
        } catch (InterruptedException e) { }
      }
    }
  }

  public Object getState() {
    return this.state;
  }
  
  protected final Set<SynchronousQueue<T>> queues;
  protected Object state;
}
