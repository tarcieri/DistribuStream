package org.pdtp;

public class Chunk {
  public Chunk(String url, long id) {
    this.url = url;
    this.id = id;
  }
  
  public long getChunkID() {
    return id;
  }
  
  public String getUrl() {
    return url;
  }
  
  @Override
  public String toString() {
    return url + "#" + id;
  }
  
  @Override
  public int hashCode() {
    return this.toString().hashCode();
  }
  
  @Override
  public boolean equals(Object o) {
    return this.toString().equals(o.toString());
  }
  
  private final String url;
  private final long id;
}
