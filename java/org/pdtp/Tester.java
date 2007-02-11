package org.pdtp;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import static java.lang.System.out;

import org.json.JSONException;

public class Tester {
  public static void main(String[] args) {
    Network N = null;
    try {
      N = new Network("localhost", 5000, new MemoryCache());
    } catch(IOException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
  
    try {
      out.println(N.getInfo("http://example.com/foo"));
    } catch (JSONException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    } catch (IOException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
  }
}
