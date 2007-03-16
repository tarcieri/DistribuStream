package org.pdtp;

import org.pdtp.wire.Range;

public class RangeTest {
  public static void main(String[] args) {
    Range r1 = new Range(0, 20);
    System.out.println("r1=" + r1);
    Range r2 = new Range(2, 4);
    Range r3 = new Range(6, 8);
    Range r4 = new Range(15, 17);
    Range r5 = new Range(0, 2);
    Range r6 = new Range(16, 25);
    System.out.println("===" + r1.less(r2, r3, r4));
    System.out.println("===" + r1.less(r3, r4, r5));
    System.out.println("===" + r1.less(r4, r5, r6));
    
    System.out.println("---" + r2.intersections(r1, r6));
  }
}
