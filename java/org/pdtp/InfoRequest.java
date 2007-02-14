package org.pdtp;

import org.pdtp.wire.TellInfo;

public class InfoRequest extends Blocker<TellInfo> {
  public InfoRequest(String url) {
    this.url = url;
  }
  
  @Override
  public boolean match(TellInfo p) {
    return p.url.equals(this.url);
  }
  
  private final String url;
}
