package org.pdtp.wire;

import java.util.Iterator;
import java.util.Set;
import java.util.SortedSet;
import java.util.TreeSet;

public class Range implements Comparable<Range> {
  public Range() {
    this.min = 0;
    this.max = 0;
  }
  
  public static long parseHTTPEntityLength(String range) {
    if("*".equals(range) || range == null) {
      return -1;
    }
    
    String[] parts = range.split("/");    
    if(parts.length == 1) return -1;

    return Long.parseLong(parts[1]);
  }
  
  public static Range parseHTTPRange(String range) {
    if(range == null) return null;
    
    // Cut away "bytes "
    range = range.substring(6);
    
    if("*".equals(range) || range == null) {
      return null;
    }
    
    String[] parts = range.split("-");    
    if(parts.length == 1) return null;
    parts[1] = parts[1].split("/")[0];
    
    long min = Long.parseLong(parts[0]);
    long max = Long.parseLong(parts[1]) + 1;
    
    return new Range(min, max);
  }
  
  public Range(final long lbound, final long ubound) {
    this.min = lbound;
    this.max = ubound;
  }
  
  public long min() {
    return min;
  }
 
  public long max() {
    return max;
  }
  
  public long size() {
    return max() - min();
  }
  
  public Range plus(Range other) {
    if(other == null) return this;
    
    if(!intersects(other))
      return null;
    
    return new Range(other.min() < this.min() ? other.min() : this.min(),
        other.max() > this.max() ? other.max() : this.max());
  }
  
  public boolean intersects(Range other) {
    if(other == null) return true;
    
    if(this.min() < other.min() && this.max() <= other.min())
      return false;
    
    if(other.min() < this.min() && other.max() <= this.min())
      return false;
    
    return true;    
  }
    
  public boolean isEmpty() {
    return min() == max();
  }
  
  public Range minus(Range other) {
    if(!this.intersects(other))
      return this;
    
    if(other.contains(this)) {
      return new Range(0, 0);
    }
    
    // Creates a hole
    if(other.min() > this.min() &&
       other.max() < this.max)
      return null;
    
    if(other.min() > this.min()) {
      return new Range(this.min(), other.min());
    } else {
      return new Range(other.max(), this.max());
    }
  }
  
  public SortedSet<Range> less(Range other) {
    SortedSet<Range> ans = new TreeSet<Range>();
    
    Range r = this.minus(other);

    if(r != null && r.isEmpty()) {
      return ans;
    }
    
    if(r != null && !r.isEmpty()) {      
      ans.add(r);
    } else {      
      Range r1 = new Range(this.min(), other.min());
      Range r2 = new Range(other.max(), this.max());
      if(!r1.isEmpty())
        ans.add(r1);
      
      if(!r2.isEmpty())
        ans.add(r2);
    }
    
    return ans;
  }
  
  public SortedSet<Range> less(Range... others) {
    SortedSet<Range> sortedOthers = new TreeSet<Range>();
    
    for(Range r : others) {
      sortedOthers.add(r);
    }
    
    return less(sortedOthers);
  }
  
  public SortedSet<Range> less(SortedSet<? extends Range> sortedOthers) {
    SortedSet<Range> ans = new TreeSet<Range>();
    
    Range current = this;    
    for(Range r : sortedOthers) {
      Set<Range> split = current.less(r);
      if(split.isEmpty()) {
        return ans;
      } else if(split.size() == 1) {
        if(r.max() >= current.max()) {
          ans.add(split.iterator().next());
          return ans;
        } else {
          current = split.iterator().next();
        }
      } else { // if(split.size() == 2)
        Iterator<Range> i = split.iterator();
        ans.add(i.next());
        current = i.next();
        
        i = split.iterator();
      }
    }
    
    ans.add(current);
    return ans;    
  }
  
  public Range intersection(Range other) {
    if(!intersects(other)) return new Range(0, 0);
    
    return new Range(this.min() >= other.min() ? this.min() : other.min(),
                     this.max() <= other.max() ? this.max() : other.max());
  }
  
  public SortedSet<Range> intersections(Range... others) {
    SortedSet<Range> ans = new TreeSet<Range>();
    
    for(Range r : others) {
      Range i = this.intersection(r);
      if(!i.isEmpty())
        ans.add(i);
    }
    
    return ans;
  }
  
  public SortedSet<Range> intersections(Iterable<? extends Range> others) {
    SortedSet<Range> ans = new TreeSet<Range>();
    
    for(Range r : others) {
      Range i = this.intersection(r);
      if(!i.isEmpty())
        ans.add(i);
    }
    
    return ans;    
  }
  
  public boolean contains(Range other) {
    if(other == null) return true;
    
    return this.max() >= other.max() && this.min() <= other.min();
  }
  
  public boolean contains(long value) {
    return value < max && value >= min;
  }
  
  @Override
  public boolean equals(Object other) {
    if(other instanceof Range) {
      Range o = (Range) other;
      
      return o.min() == min() && o.max() == max();
    } else {
      return false;
    }
  }    
  
  @Override
  public String toString() {
    return min + "-" + max;
  }
  
  @Override
  public int hashCode() {
    return this.toString().hashCode();
  }
  
  public int compareTo(Range other) {
    Long l = new Long(min());
    return l.compareTo(new Long(other.min()));
  }
  
  public long min;
  public long max;  
}
