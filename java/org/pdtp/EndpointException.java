package org.pdtp;

import java.io.IOException;

public class EndpointException extends IOException {
  private static final long serialVersionUID = -1461476849964593368L;

  public EndpointException(Throwable cause) {
    super(cause.toString());
    setStackTrace(cause.getStackTrace());
  }
}
