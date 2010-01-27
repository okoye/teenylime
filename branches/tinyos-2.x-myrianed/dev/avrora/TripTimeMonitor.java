/**
 * Copyright (c) 2004-2005, Regents of the University of California
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * Neither the name of the University of California, Los Angeles nor the
 * names of its contributors may be used to endorse or promote products
 * derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package avrora.monitors;

import avrora.Avrora;
import avrora.core.LabelMapping;
import avrora.core.Program;
import avrora.core.SourceMapping;
import avrora.core.SourceMapping.Location;
import avrora.sim.Simulator;
import avrora.sim.State;
import avrora.util.Option;
import avrora.util.StringUtil;
import avrora.util.TermUtil;
import avrora.util.Terminal;
import avrora.util.profiling.Distribution;

import java.util.Iterator;

/**
 * The <code>TripTimeMonitor</code> class implements a monitor that tracks the time from
 * executing instruction A in the program until the program reaches instruction B. For
 * example, if A is the beginning of an interrupt handler and B is the end of an interrupt
 * handler, then the monitor will record the time it takes to execute the entire interrupt
 * handler. For each pair of points A and B, it collects statistics about each "trip"
 * between the two points, reporting the results at the end of execution. 
 *
 * @author Ben L. Titzer
 */
public class TripTimeMonitor extends MonitorFactory {

	static final int CYCLES_PER_US = 8;
	static final int MAX_LABEL_LENGTH = 18;
	int lineIndent = 0;
	
    final Option.List PAIRS = options.newOptionList("pairs", "",
            "The \"pairs\" option specifies the list of program point pairs for which " +
            "to measure the point-to-point trip time. ");
    final Option.List FROM = options.newOptionList("from", "",
            "The \"from\" option specifies the list of program points for which " +
            "to measure to every other instruction in the program. ");
    final Option.List TO = options.newOptionList("to", "",
            "The \"from\" option specifies the list of program points for which " +
            "to measure from every other instruction in the program. ");
    final Option.Bool DISTRIBUTION = options.newOption("distribution", false,
            "This option, when specified, causes the trip time monitor to print a complete distribution of the " +
            "trip times for each pair of program points. WARNING: this option can consume large amounts of memory " +
            "and generate a large amount of output.");

    public TripTimeMonitor() {
        super("The \"trip-time\" monitor records profiling " +
                "information about the program that consists of the time it takes " +
                "(on average) to reach one point from another point in the program.");
    }

    protected class PointToPointMon implements Monitor {

        class Pair {
            int start;
            int end;
            long cumul;
			long cumul_sqr;
            int count;
			long max;
			long min;
			Location startLoc, endLoc;
			int max_count = 1; 
			boolean stopped = false;

            Pair startLink;
            Pair endLink;

            Distribution distrib;


            Pair(int start, int end) {
            	init(start, end);
            }           
            
            Pair(Location start, Location end) {
            	init(start.address, end.address);
            	startLoc = start;
            	endLoc = end;
            }
            
            void init(int start, int end) {
            	this.start = start;
                this.end = end;

				this.cumul = 0;
				this.cumul_sqr = 0;
				this.max = 0;
				this.min = Long.MAX_VALUE;
                if ( DISTRIBUTION.get() )
                    distrib = new Distribution("trip time "
                            +StringUtil.addrToString(start)+" -to- "
                            +StringUtil.addrToString(end), "Trips", "Total Time", "Distribution");
            }

            void record(long time) {
            	if (stopped) {
            		return;
            	}
                if ( distrib != null ) {
                    distrib.record((int)time);
                } else {
                    cumul += time;
					cumul_sqr += (time * time);
					max = Math.max(max, time);
					min = Math.min(min, time);
                }
                count++;
                if (max_count == count) {
            		stopped = true;
                }
                report();
            }

 	void report() {
            	
                if ( distrib == null ) {
                float avg = (float)cumul / count;
				double std = Math.sqrt(((double)cumul_sqr / count) - (avg * avg));
				if (startLoc.name != null) {
					Terminal.print(""+StringUtil.leftJustify(startLoc.name+",",MAX_LABEL_LENGTH));
				} else {
					Terminal.print(""+StringUtil.leftJustify(StringUtil.addrToString(start)+",",MAX_LABEL_LENGTH));
				}
				if (endLoc.name != null) {
					Terminal.print(""+StringUtil.leftJustify(endLoc.name+",",MAX_LABEL_LENGTH));
				} else {
					Terminal.print(""+StringUtil.leftJustify(StringUtil.addrToString(start)+",",MAX_LABEL_LENGTH));
				}
                Terminal.println("  "                        
                        +StringUtil.rightJustify((float)avg/CYCLES_PER_US, 9)+"us  ");
                } else {
                    distrib.processData();
                    distrib.textReport();
                }
            }
        }

        final Pair[] startArray;
        final Pair[] endArray;
        Pair[] sortedPairs;
        int sortedPairsLength;
        final long[] lastEnter;

        final Simulator simulator;
        final Program program;
        final PTPProbe PROBE;
        long lastTime = 0;

        PointToPointMon(Simulator s) {
            simulator = s;
            program = s.getProgram();
            int psize = program.program_end;
            startArray = new Pair[psize];
            endArray = new Pair[psize];
            lastEnter = new long[psize];
            PROBE = new PTPProbe();
            sortedPairsLength = 0;
            sortedPairs = new Pair[psize];

            addPairs();
            addFrom();
            addTo();
        }

        private void addPairs() {
            Iterator i = PAIRS.get().iterator();
            while (i.hasNext()) {
                String str = (String)i.next();
                int ind = str.indexOf(":");
                if (ind <= 0) {
                	return;
//                	throw Avrora.failure("invalid address format: " + StringUtil.quote(str));
                }
                String src = str.substring(0, ind);
                String dst = str.substring(ind + 1);

                LabelMapping.Location loc = getLocation(src);
                LabelMapping.Location tar = getLocation(dst);
                
                if (loc != null && tar != null) {
                	addPair(loc, tar);
                }
            }
        }

		private LabelMapping.Location getLocation(String src) {
            SourceMapping lm = program.getSourceMapping();
            SourceMapping.Location loc = lm.getLocation(src);
            if ( loc == null ) {
            	Terminal.printRed("Invalid program address:" + src + "\n");
            	return null;
            }
            if ( program.readInstr(loc.address) == null ) {
            	Terminal.printRed("Invalid program address:" + src + "\n");
            	return null;
            }
            return loc;
        }

        private void addFrom() {
            Iterator i = FROM.get().iterator();
            SourceMapping sm = program.getSourceMapping();
            while (i.hasNext()) {
                String str = (String)i.next();
                SourceMapping.Location loc = sm.getLocation(str);
                for ( int cntr = 0; cntr < program.program_end; cntr = program.getNextPC(cntr) )
                    addPair(loc.address, cntr);
            }
        }

        private void addTo() {
            Iterator i = TO.get().iterator();
            SourceMapping sm = program.getSourceMapping();
            while (i.hasNext()) {
                String str = (String)i.next();
                SourceMapping.Location loc = sm.getLocation(str);
                for ( int cntr = 0; cntr < program.program_end; cntr = program.getNextPC(cntr) )
                    addPair(cntr, loc.address);
            }
        }

        private void addPair(Location start, Location end) {
            if ( program.readInstr(start.address) == null ) return;
            if ( program.readInstr(end.address) == null ) return;

            Pair p = new Pair(start, end);

            if (startArray[p.start] == null && endArray[p.start] == null)
                simulator.insertProbe(PROBE, p.start);

            p.startLink = startArray[p.start];
            startArray[p.start] = p;

            if (startArray[p.end] == null && endArray[p.end] == null)
                simulator.insertProbe(PROBE, p.end);


            p.endLink = endArray[p.end];
            endArray[p.end] = p;
		}
        
        void addPair(int start, int end) {

            if ( program.readInstr(start) == null ) return;
            if ( program.readInstr(end) == null ) return;

            Pair p = new Pair(start, end);

            if (startArray[p.start] == null && endArray[p.start] == null)
                simulator.insertProbe(PROBE, p.start);

            p.startLink = startArray[p.start];
            startArray[p.start] = p;

            if (startArray[p.end] == null && endArray[p.end] == null)
                simulator.insertProbe(PROBE, p.end);


            p.endLink = endArray[p.end];
            endArray[p.end] = p;
        }

        protected class PTPProbe extends Simulator.Probe.Empty {
            public void fireBefore(State state, int pc) {
                long time = state.getCycles();
                
                for ( Pair p = endArray[pc]; p != null; p = p.startLink ) {
                    if ( lastEnter[p.start] < 0 ) continue;
                    if (!p.stopped) {
                    	sortedPairs[sortedPairsLength++] = p;
                    	addPair(p.startLoc, p.endLoc);
                    }
                    p.record(time - lastEnter[p.start]);
                }
                lastEnter[pc] = time;
            }
        }

        public void report() {
        	
          Terminal.printGreen("cumulative time (in us) per profile pair");
          Terminal.nextln();
          Terminal.println(""+StringUtil.leftJustify("st labl,",MAX_LABEL_LENGTH) + StringUtil.leftJustify("end labl,",MAX_LABEL_LENGTH) + StringUtil.rightJustify("  time,  ", 13)+StringUtil.rightJustify("count", 6));
          TermUtil.printThinSeparator(Terminal.MAXLINE);
          
          for (int pc = 0; pc < program.program_end; pc++) { 
            float sum = 0;
            int count = 0;
            for ( Pair p = endArray[pc]; p != null; p = p.startLink ) {
              if (p.count <= 0) continue;
              sum += p.cumul;
              count++;
            }
            Pair p = endArray[pc];
            if (p == null) continue;
            if (p.startLoc == null) continue;
            if (p.startLoc.name != null) {
                    Terminal.print(""+StringUtil.leftJustify(p.startLoc.name+",",MAX_LABEL_LENGTH));
            } else {
                    Terminal.print(""+StringUtil.leftJustify(StringUtil.addrToString(p.start)+",",MAX_LABEL_LENGTH));
            }
            if (p.endLoc.name != null) {
                    Terminal.print(""+StringUtil.leftJustify(p.endLoc.name+",",MAX_LABEL_LENGTH));
            } else {
                    Terminal.print(""+StringUtil.leftJustify(StringUtil.addrToString(p.start)+",",MAX_LABEL_LENGTH));
            }
            Terminal.println("  "                        
                    +StringUtil.rightJustify((float)sum/CYCLES_PER_US, 9)+",  "+StringUtil.rightJustify(count, 6));
          }
       }
    }

    public Monitor newMonitor(Simulator s) {
        return new PointToPointMon(s);
    }
}
