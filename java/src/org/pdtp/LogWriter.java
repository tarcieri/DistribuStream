package org.pdtp;

import org.pdtp.Logger.Level;

public interface LogWriter {
  void log(Level level, Object message);
}
