package org.pdtp;

import java.util.HashMap;
import java.util.Map;

public class Tester {
  public static void main(String[] args) {
    Network N = new Network(new MemoryCache());
  
    String[] peers = { "A", "B", "C" };
  
    Map<String, String> t = new HashMap<String, String>();
    t.put("url", "http://www.example.com/");
    t.put("id", "22");
    t.put("from", "server");
    t.put("direction", "out");
    t.put("type", "transfer");    
    
    N.dispatch(t, null);
    N.dispatch(t, null);
  }
}
