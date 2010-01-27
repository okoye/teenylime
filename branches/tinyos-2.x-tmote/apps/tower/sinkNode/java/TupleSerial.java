/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * The Class TupleSerial.
 * 
 * This class sends and receives tuples from the serial.
 * 
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @author Matteo Ceriotti <a href="mailto:ceriotti@fbk.eu">ceriotti@fbk.eu</a>
 */

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class TupleSerial implements MessageListener {
  
  private MoteIF node;
  private TupleManager manager;
  private TupleSerialMsg msg;
  private boolean active;
  private BufferedReader reader;
  
  public TupleSerial(MoteIF node, TupleManager manager) {
    this.node = node;
    this.manager = manager;
    this.reader = new BufferedReader(new InputStreamReader(System.in));
  }
  
  private void sendTuple(){
    System.out.print("Sending tuple...");
    try {
      node.send(MoteIF.TOS_BCAST_ADDR, msg);
      System.out.println("sent");
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
  
  private void readTask(){
    msg = new TupleSerialMsg();
    try {
      int type = 0;
      int s = 0;
      int r = 0;
      int t = 0;
      int o = 0;
      boolean valid = false;
      System.out.println("Task Definition: 1) Acceleration 2) Temperature and humidity");
      while (!valid) {
        try {
          type = Integer.parseInt(reader.readLine());
          valid = true;
        } catch (NumberFormatException e) {
          e.printStackTrace();
        }
      }
      valid = false;
      switch(type){
      case 1:
        System.out.println("ACCELERATION TASK DEFINITION");
        System.out
          .println("Insert the sampling rate (R) in Hz");
        while (!valid) {
          try {
            r = Integer.parseInt(reader.readLine());
            valid = true;
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
        }
        valid = false;
        System.out
          .println("Insert the sampling duration (S) in seconds");
        while (!valid) {
          try {
            s = Integer.parseInt(reader.readLine());
            valid = true;
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
        }
        valid = false;
        System.out
          .println("Insert the interval between samples (T) in minutes");
        while (!valid) {
          try {
            t = Integer.parseInt(reader.readLine());
            valid = true;
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
        }
        valid = false;
        System.out
          .println("Insert the opearting time (O) in minutes(-1 for an infinite operating time)");
        while (!valid) {
          try {
            o = Integer.parseInt(reader.readLine());
            if (o == -1){
              o = Properties.INFINITE_OP_TIME;
            }
            valid = true;
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
        }
        msg.setElement_tuple_fields_type(0, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(0, 0);
        msg.setElement_tuple_fields_type(1, Properties.TYPE_UINT8);
        msg.setElement_tuple_fields_value_int8(1, Properties.VIBRATION_TYPE);
        msg.setElement_tuple_fields_type(2, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(2, r);
        msg.setElement_tuple_fields_type(3, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(3, s);
        msg.setElement_tuple_fields_type(4, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(4, t);
        msg.setElement_tuple_fields_type(5, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(5, o);
        for (int i = 6; i<TupleSerialMsg.numElements_tuple_fields_type(); i++){
          msg.setElement_tuple_fields_type(i, (short) (Properties.TYPE_EMPTY |
                                                       Properties.TYPE_FORMAL));
        }
        break;
      case 2:
        
        System.out.println("TEMPERATUTE/DEFORMATION TASK DEFINITION");
        System.out
          .println("Insert the interval between samples (T) in minutes");
        while (!valid) {
          try {
            t = Integer.parseInt(reader.readLine());
            valid = true;
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
        }
        valid = false;
        System.out
          .println("Insert the opearting time (O) in minutes(-1 for an infinite operative time)");
        while (!valid) {
          try {
            o = Integer.parseInt(reader.readLine());
            if (o == -1){
              o = Properties.INFINITE_OP_TIME;
            }
            valid = true;
          } catch (NumberFormatException e) {
            e.printStackTrace();
          }
        }
        msg.setElement_tuple_fields_type(0, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(0, 0);
        msg.setElement_tuple_fields_type(1, Properties.TYPE_UINT8);
        msg.setElement_tuple_fields_value_int8(1, Properties.TEMP_DEFORM_TYPE);
        msg.setElement_tuple_fields_type(2, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(2, Properties.INSTANT);
        msg.setElement_tuple_fields_type(3, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(3, Properties.INSTANT);
        msg.setElement_tuple_fields_type(4, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(4, t);
        msg.setElement_tuple_fields_type(5, Properties.TYPE_UINT16);
        msg.setElement_tuple_fields_value_int16(5, o);
        for (int i = 6; i<TupleSerialMsg.numElements_tuple_fields_type(); i++){
          msg.setElement_tuple_fields_type(i, (short) (Properties.TYPE_EMPTY |
                                                       Properties.TYPE_FORMAL));
        }
        break;
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
  
  public void activate(){
    String again = "";
    node.registerListener(new TupleSerialMsg(), this);
    manager.activate();
    active = true;
    while (active){
      msg = new TupleSerialMsg();
      readTask();
      sendTuple();
    }
  }
  
  public void messageReceived(int to, Message message) {
    if (message instanceof TupleSerialMsg) {
      manager.tupleReceived((TupleSerialMsg) message);
    } else if (message instanceof PrintfMsg) {
      PrintfMsg msg = (PrintfMsg) message;
      for (int i = 0; i < PrintfMsg.totalSize_buffer(); i++) {
        char nextChar = (char) (msg.getElement_buffer(i));
        if (nextChar != 0)
          System.out.print(nextChar);
      }
    }
  }
  
  private static void man() {
    System.err
      .println("help: TupleSerial -t <log_mode> -comm <source>");
    System.err.println("-t <log_mode> options: file");
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    TupleManager manager = null;
    if (args.length == 4) {
      if (args[0].equals("-t")) {
        if (args[1].equals("file")) {
          manager = new TupleLogFileManager();
        } else {
          man();
          System.exit(1);
        }
      } else {
        man();
        System.exit(1);
      }
      if (args[2].equals("-comm")) {
        source = args[3];
      } else {
        man();
        System.exit(1);
      }
    } else {
      man();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    } else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }
    MoteIF mif = new MoteIF(phoenix);
    TupleSerial serial = new TupleSerial(mif, manager);
    serial.activate();
  }
  
}
