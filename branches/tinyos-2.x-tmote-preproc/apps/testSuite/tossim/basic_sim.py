# PROJECT
#   TeenyLIME
# VERSION
#   $LastChangedRevision: 136 $
# DATE
#   $LastChangedDate: 2007-10-15 16:26:10 +0200 (Mon, 15 Oct 2007) $
# LAST_CHANGE_BY
#   $LastChangedBy: lmottola $
# 
#   $Id: basic_sim.py 136 2007-10-15 14:26:10Z sguna $
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

# A simple python script to drive a python simulation.
# 
# Author: Stefan Guna
#       <a href="mailto:guna@disi.unitn.it">guna@disi.unitn.it</a>  



from TOSSIM import *
import sys, StringIO
import random
import os

# The maximum number of lines to load from the noise file.
max_noise_lines = 100

# Creates the network topology from a file containing gain values for each
# pair of nodes. Each line of the file must have the following format:
#
# src_node dest_node link_gain
#
# For instance: 0 5 -90.71
# NOTE: The first node ID is 0.
def load_topology(r, topology_file):
    f = open(topology_file, "r")
    nodes_count = 0

    lines = f.readlines()
    for line in lines: 
        s = line.split() 
        if (len(s) > 0): 
            r.add(int(s[0]), int(s[1]), float(s[2].replace(',', '.')))
            if (int(s[0]) > nodes_count):
                nodes_count = int(s[0])
            if (int(s[1]) > nodes_count):
                nodes_count = int(s[1])
    f.close()

    nodes_count += 1
    print "Found", nodes_count, "nodes";
    return nodes_count


def load_noise(t, nodes_count):
    noiseFile = os.environ["TOSROOT"] + "/tos/lib/tossim/noise/meyer-heavy.txt"
    noise = open(noiseFile, "r")
    lines = noise.readlines()
    lines_cnt = 0
    for line in lines:
        lines_cnt += 1
        if (lines_cnt > max_noise_lines):
            break
        str = line.strip()
        if (str!= ""):
            val = int(str)
            for i in range(0, nodes_count):
                t.getNode(i).addNoiseTraceReading(val)

    for i in range(0, nodes_count):
        print "Creating noise model for", i;
        t.getNode(i).createNoiseModel()


# Configures each node to boot at a random time
def config_boot(t, nodes_count):
    for i in range(0, nodes_count):
        bootTime = random.randint(1, 1000000)
        print "Node", i, "booting at", bootTime;
        t.getNode(i).bootAtTime(bootTime)


def simulation_loop(t, sim_time):
    t.runNextEvent()
    startup_time = t.time()
    while (t.time() < startup_time + sim_time * 10000000):
        t.runNextEvent()


# Runs a simulatio for sim_time (in ms) on the network defined in topology_file
def run_simulation(sim_time, topology_file):
    t = Tossim([])
    r = t.radio()

    nodes_count = load_topology(r, topology_file)
    load_noise(t, nodes_count)
    config_boot(t, nodes_count)

# Add channels here. For instance:
    t.addChannel("app", sys.stdout)
    simulation_loop(t, sim_time)


# Make a call to run_simulation here
run_simulation(6000000, "topology.out")
