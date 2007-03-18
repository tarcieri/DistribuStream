package org.pdtp;

import java.io.IOException;

public interface Endpoint {
  public Object take() throws IOException;
  public void send(Object packet) throws IOException;
}
