package org.pdtp.wire;

public class AskInfo {
  public AskInfo() {
    this.url = "<UNDEFINED>";
  }
  
  public AskInfo(String url) {
    this.url = url;
  }
  
  public String url;
}
