/********************************************************************
 * File Name:    MyDummy01Test.java
 *
 * Date Created: Dec 28, 2017
 *
 * ------------------------------------------------------------------
 * 
 * Copyright (c) 2017 ajeydudhe@gmail.com
 *
 *******************************************************************/

package my.pocs;

import static org.junit.Assert.*;

import org.junit.Test;

public class MyDummy01Test
{
  @Test
  public void quickTest()
  {
    assertTrue(true != false);
  }

  @Test
  public void longTest() throws InterruptedException
  {
    Thread.sleep(1000 * 10);
  }
}

