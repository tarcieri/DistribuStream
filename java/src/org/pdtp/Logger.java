package org.pdtp;

import java.io.OutputStream;
import java.io.PrintStream;

public class Logger {
  public static enum Level { TRACE, DEBUG, INFO, WARN, ERROR, FATAL, OFF };
  
  public static void setOutputStream(OutputStream out) {
    writer = new OutputStreamWriter(out);
  }
  
  public static void setLogWriter(LogWriter w) {
    writer = w;
  }
  
  public static void setLogLevel(Level level) {
    logLevel = level;
  }
  
  public static void trace(Object message) {
    log(Level.TRACE, message);
  }
  
  public static void debug(Object message) {
    log(Level.DEBUG, message);
  }
  
  public static void info(Object message) {
    log(Level.INFO, message);
  }
  
  public static void warn(Object message) {
    log(Level.WARN, message);
  }
  
  public static void error(Object message) {
    log(Level.ERROR, message);
  }
  
  public static void fatal(Object message) {
    log(Level.FATAL, message);    
  }

  public static void log(Level level, Object message) {
    if(writer != null) { writer.log(level, message); }
  }
  
  private static class OutputStreamWriter implements LogWriter {
    private OutputStreamWriter(OutputStream out) {
      this.stream = new PrintStream(out);
    }
    
    public synchronized void log(Level level, Object message) {
      if(message != null && level != null)
        stream.println("[" + level + "]\t" + message.toString());
    }
    
    private PrintStream stream;
  }
  
  private static Level logLevel = Level.WARN;
  private static LogWriter writer = new OutputStreamWriter(System.err);
}
