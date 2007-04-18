package org.pdtp;

import java.io.IOException;

/**
 * Endpoints are abstractions which can send and receive network messages.
 * 
 */

public interface Endpoint {
  /**
   * Reads an object from the network. This method will block until
   * one object is read, or until the connection is closed.
   * 
   * @return the received object, or null if the connection closed.
   * @throws IOException
   */
  public Object take() throws IOException;
  
  /**
   * Writes an object to the network.
   * 
   * @param packet the object to be sent
   * @throws IOException
   */
  public void send(Object packet) throws IOException;
  
  /**
   * Returns true if the endpoint is open, false otherwise.
   * 
   * @return true if the endpoint is open.
   */
  public boolean isOpen();
}
