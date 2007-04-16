package org.pdtp;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Endpoints use Serializers to encode objects for transfer over
 * the network.
 * 
 */
public interface Serializer {
  /**
   * Read a single object from the specified stream, and return it.
   * This method should block until an object is read.
   * 
   * @param stream the input stream
   * @return the object read
   * @throws IOException
   */
  public Object read(InputStream stream) throws IOException;
  
  /**
   * Write a single object to the specified stream.
   * This method may or may not block until the object is written.
   * 
   * @param obj the object to serialize
   * @param stream the destination serialization stream
   * @throws IOException
   */
  public void write(Object obj, OutputStream stream) throws IOException;
}
