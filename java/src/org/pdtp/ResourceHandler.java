package org.pdtp;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;

import org.pdtp.wire.TellInfo;
import org.pdtp.wire.Transfer;

public interface ResourceHandler {
  public void transferCommand(Transfer t);  
  public ReadableByteChannel getCached(Resource r) throws IOException;
  public TellInfo getInfoCached(String uri);
  public ByteBuffer postRequested(Resource r);
  public void postComplete(ByteBuffer b, Resource r, String host, int port);
  public void infoReceived(TellInfo info);
}
