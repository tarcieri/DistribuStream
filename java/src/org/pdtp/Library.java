package org.pdtp;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;
import java.util.Set;

import org.pdtp.wire.Range;

/**
 * The Library interface is a caching abstraction. Libraries are expected to
 * be able to store and receive arbitrary file ranges. Depending on the
 * implementatio, data stored within a library may change unpredictably (for
 * example, in response to file deletion, for a filesystem-backed library).
 */
public interface Library {
  /**
   * Returns true if this library contains the specified resource.
   * 
   * @param resource the resource being checked for
   * @return true if the resouce is present in this library
   */
  public boolean contains(Resource resource);
  
  /**
   * Returns the parts of the specified resouce which are missing
   * from this library. If the resource isn't in this library at all,
   * returns [0, inf].
   * 
   * @param resource the resorce being looked at
   * @return a set of ranges indicating chunks of data not stored in
   *         this library
   */
  public Set<Range> missing(Resource resource);
  
  /**
   * Allocates a ByteBuffer backing against whatever storage medium
   * this library uses. Only buffers returned by this function may
   * be used to call write.
   * 
   * @param size the buffer's size
   * @return a new buffer, suitable for storing data in this library
   */
  public ByteBuffer allocate(long size);
  
  /**
   * Writes a chunk of data to this library. The buffer passed into
   * this function must have been allocated with the allocate function
   * of the same library.
   * 
   * @param resource the resource to write to
   * @param buffer a buffer containing the data to write.
   */
  public void write(Resource resource, ByteBuffer buffer);
  
  /**
   * Reads a resouce from this library.
   * 
   * If blocking is true, then the resource need not exist at all at
   * the time this method is called. The channel will simply block until
   * data is available.
   * 
   * If blocking is false, then the complete resource must exist when the
   * call is made, otherwise the function returns null.
   * 
   * Data is always served in order. For blocking channels, this means that
   * even a single missing byte will block the channel until it is filled.
   * 
   * @param resource the resource to read
   * @param blocking true if the returned channel should block until data
   *        is available
   * @return a channel streaming data out of this library
   * @throws IOException
   */
  public ReadableByteChannel getChannel(Resource resource,
      boolean blocking) throws IOException;
}
