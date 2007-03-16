package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public interface Serializer {
  public Object read(InputStream stream) throws IOException;
  public void write(Object obj, OutputStream stream) throws IOException;
}
