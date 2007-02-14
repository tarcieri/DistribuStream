package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

import org.json.JSONObject;

public class JSONSerializer implements Serializer {
  public JSONSerializer(String basePackage) {
    this.basePackage = basePackage;    
  }
  
  public Object read(InputStream in) throws IOException {
    String json = readJSON(in);
    
    System.out.println("READ: " + json);
    
    JSONObject obj = null;
    try {
      obj = new JSONObject(json);    
      String className = underscoreToCamel(obj.get("type").toString(), true);
      className = basePackage + "." + className;
      Class c = Class.forName(className);
      Object o = c.newInstance();
      for(Field f : c.getFields()) {
        String usName = camelToUnderscore(f.getName());
        
        if(obj.has(usName)) {
          f.set(o, obj.get(usName));
        }
      }
      
      return o;
    } catch (Exception e) {
      throw new EndpointException(e);
    }
  }

  public void write(Object obj, OutputStream stream) throws IOException {
    try {
      JSONObject json = new JSONObject(mapify(obj));
      json.put("type", camelToUnderscore(obj.getClass().getSimpleName()));
      System.out.println("SEND: " + json.toString());
      stream.write((json.toString() + "\n").getBytes());
    } catch (Exception e) {
      throw new EndpointException(e);
    }
  }

  public Map<String, Object> mapify(Object obj) throws IllegalArgumentException, IllegalAccessException {
    Class c = obj.getClass();
    HashMap<String, Object> map = new HashMap<String, Object>();
    
    for(Field f : c.getFields()) {
      String usName = camelToUnderscore(f.getName());
      
      Object val = f.get(obj);
      if(val instanceof Boolean ||
         val instanceof Double ||
         val instanceof Integer ||
         val instanceof String ||
         val instanceof Float ||
         val instanceof Short ||
         val instanceof Character) {
        map.put(usName, val);
      } else {
        map.put(usName, mapify(val));
      }
    }
    
    return map;
  }
  
  private String readJSON(InputStream in) throws IOException {
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
  
  private String underscoreToCamel(String underscored, boolean upper) {
    String output = "";

    for(char c : underscored.toCharArray()) {
      if(c == '_') {
        upper = true;
      } else {
        output += upper ? Character.toUpperCase(c) : c;        
        upper = false;
      }
    }
    
    return output;
  }
  
  private String camelToUnderscore(String cameled) {
    LinkedList<String> words = new LinkedList<String>();
    String word = "";
    
    for(char c : cameled.toCharArray()) {
      if("".equals(word)) {
        word += c;
      } else {
        if(Character.isUpperCase(c)) {
          if(Character.isUpperCase(word.charAt(word.length() - 1))) {
            word += c;
          } else {
            words.add(word);
            word = "" + c;
          }
        } else {
          if(Character.isUpperCase(word.charAt(word.length() - 1))) {
            if(word.length() > 1) {
              char last = word.charAt(word.length() - 1);
              word = word.substring(0, word.length() - 1);
              words.add(word);
              word = "" + last + c;
            } else {
              word += c;
            }
          } else {
            word += c;
          }
        }
      }
    }
    
    words.add(word);
    
    String output = "";
    
    for(String w : words) {      
      if(!("".equals(w))) {
        output += w.toLowerCase() + '_';
      }
    }    
    
    output = output.substring(0, output.length() - 1);
    return output;
  }
  
  private final String basePackage;
}
