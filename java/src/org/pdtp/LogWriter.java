package org.pdtp;

import org.pdtp.Logger.Level;

/**
 * The LogWriter interface is used to provide simple but very flexible
 * logging for applications.
 */
public interface LogWriter {
  /**
   * Called whenever a logging message is received. Level indicates
   * the message's level (Trace, Warn, Debug, etc...).
   * 
   * @param level
   * @param message
   */
  void log(Level level, Object message);
}
