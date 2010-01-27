# PROJECT
#   TeenyLIME
# VERSION
#   $LastChangedRevision: 136 $
# DATE
#   $LastChangedDate: 2007-10-15 16:26:10 +0200 (Mon, 15 Oct 2007) $
# LAST_CHANGE_BY
#   $LastChangedBy: lmottola $
# 
#   $Id: PingPong.py 136 2007-10-15 14:26:10Z lmottola $
#  
#   TeenyLIME - Transiently Shared Tuple Space Middleware for
#               Wireless Sensor Networks
#  
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#  
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#  
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, you may find a copy at the FSF web
#   site at 'www.gnu.org' or 'www.fsf.org', or you may write to the
#   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#   Boston, MA  02111-1307, USA

# A simple python script to run PingPongPull and PingPongPush in TOSSIM.
# 
# Author: Luca Mottola
#       <a href="mailto:mottola@elet.polimi.it">mottola@elet.polimi.it</a>  

import sys
import os
from TOSSIM import *

t = Tossim([]);
r = t.radio();

# Instantiating a pair of nodes - one of the two nodes must correspond to 
# the STARTING_NODE_ID in Constants.h
m1 = t.getNode(10);
m2 = t.getNode(11);

# Let them boot at random times
m1.bootAtTime(100001);
m2.bootAtTime(800008);
 
# Set a radio link
r.add(10, 11, -65.0);
r.add(11, 10, -65.0);

# Creating noise model
tosroot = os.getenv("TOSROOT");
noise = open(tosroot+"/tos/lib/tossim/noise/meyer-heavy.txt", "r")
lines = noise.readlines()
print "adding noise trace reading"
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(10, 12):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(10, 12):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

# Set debug ouput channels
t.addChannel("DBG_USR1", sys.stdout);
t.addChannel("DBG_ERROR", sys.stdout);
t.addChannel("DBG_SLAB", sys.stdout);

# Simulates two minutes since the first node boot 
t.runNextEvent();
time = t.time()
while (time + 2400000000000 > t.time()):
  t.runNextEvent()

