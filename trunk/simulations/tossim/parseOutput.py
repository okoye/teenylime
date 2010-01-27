#!/usr/bin/python

import sys
import getopt
import os
import math
from Numeric import *
import Gnuplot, Gnuplot.funcutils
from Scientific.Statistics import average, standardDeviation

def usage():
    print """Usage: ./parseOutput.py -d RELIABLE_DIR  [--verbose] [-f GNUPLOT_FILE] [-a ADD_FILE -v VALUE]"""
    
def time2sec(timeString):
    timeString = timeString.strip('[').strip(']')
    hours = int(timeString.split(':')[0])
    mins =  int(timeString.split(':')[1])
    secs =  float(timeString.split(':')[2])
    if(secs >= int(secs) + 0.5):
        secs = int(math.ceil(secs))
    else:
        secs = int(math.floor(secs))
    timeSec = 3600*hours + 60*mins + secs
    return timeSec

class Message(object):
    def __init__(self, msgId, kind, recipients, time):
        self.msgId = msgId
        self.kind = kind
        self.recipients = recipients
        self.toDeliver = len(recipients)
        self.delivered = 0
        self.sent = -1 # decremented to account for retransmissions (was 0)
        self.creationTime = time
        self.arrivalTime = []
        self.sentPerRecipient = []
    def __str__(self):
        return "Msg " + str(self.msgId) + "(" + self.kind + ") to be delivered to " + str(self.recipients) + " created at " + str(self.creationTime)
    __repr__ =  __str__
    def receivedBy(self, recipient,time):
        if(recipient in self.recipients):
            self.recipients.remove(recipient)
            self.delivered += 1
            self.sentPerRecipient.append(self.sent)
            self.arrivalTime.append(time)
    def msgSent(self):
        self.sent += 1
    def getStats(self):
        if(self.toDeliver > 0):
            delivery = (float(self.delivered)) / self.toDeliver
        else:
            delivery = -1
        return (delivery, self.sent)
    def getCostPerNeighbor(self):
        return self.sentPerRecipient
    

class Node(object):
    def __init__(self, nodeId):
        self.msgs = {}
        self.nonCritical = {}
        self.critical = 0
        self.role = "UNKNOWN"
        self.nodeId = nodeId
        self.neighbors = []
        self.symmetricNeighbors = []
    def setRole(self, role):
        self.role = role
    def addMessage(self, msg):
        self.msgs[msg.msgId] = msg
        self.critical += 1
    def msgReceived(self, msgId, recipient,time):
        if(self.msgs.has_key(msgId)):
            self.msgs[msgId].receivedBy(recipient,time)
    def msgSent(self, msgId, kind):
        if(self.msgs.has_key(msgId)):
            self.critical += 1
            self.msgs[msgId].msgSent()
        if(self.nonCritical.has_key(kind)):
            self.nonCritical[kind] += 1
        else:
            self.nonCritical[kind] = 1
    def removeNeighbor(self, neighbor):
        for m in self.msgs.itervalues():
            if(neighbor in m.recipients):
                m.recipients.remove(neighbor)
                m.toDeliver -=1
    def getCriticalStats(self, lowerTime, upperTime):
        delivery = []
        overhead = []

        for msgId,msg in self.msgs.iteritems():
            if(msg.creationTime <= upperTime and msg.creationTime > lowerTime):
                d,o = msg.getStats()
                if(d != -1):
                    delivery.append(d)
                    overhead.append(o)
                    if(verbose and d < 1):
                        print "Node: %s, msgId: %s, delivery:%f, recipients=" % (self.nodeId,msgId, d) + str(msg.recipients)
                                        
        return delivery,overhead
    def getCostPerNeighbor(self,lowerTime, upperTime):
        sentPerRecipient = []
        for msg in self.msgs.itervalues():
            if(msg.creationTime <= upperTime and msg.creationTime > lowerTime):
                d,o = msg.getStats()
                if(d != -1):
                    sentPerRecipient.extend(msg.getCostPerNeighbor())
        return sentPerRecipient
    def __str__(self):
        return self.role + " Messages " + str(self.msgs)
    __repr__ =  __str__


class Run(dict):
    def __str__(self):
        return dict.__str__(self)
    __repr__ =  __str__
    def getCriticalStats(self, lowerTime, upperTime):
        delivery = []
        overhead = []
        for node in self.itervalues():
            d,o = node.getCriticalStats(lowerTime, upperTime)
            delivery.extend(d)
            overhead.extend(o)

        if(len(delivery) == 0):
            return -1,-1
        elif(len(delivery) == 1):
            return delivery[0],overhead[0]
        else:
            avgDelivery = average(delivery)
            avgOverhead = average(overhead)
            return avgDelivery, avgOverhead
    def getCostPerNeighbor(self, lowerTime, upperTime):
        sentPerRecipient = []
        for node in self.itervalues():
            sentPerRecipient.extend(node.getCostPerNeighbor(lowerTime,upperTime))

        # Find max and min
        maxNgh = -1
        minNgh = sys.maxint
        for i in sentPerRecipient:
            if(i > maxNgh):
                maxNgh = i                
            if(i < minNgh):
                minNgh = i
        if(len(sentPerRecipient) == 0):
            return -1,-1,-1,-1
        elif(len(sentPerRecipient) == 1):
            return sentPerRecipient[0],0,sentPerRecipient[0],sentPerRecipient[0]
        else:
            return average(sentPerRecipient), standardDeviation(sentPerRecipient),minNgh,maxNgh
    def getTotalMessages(self):
        otherMsgs = { }
        for node in self.itervalues():
            for kind, count in node.nonCritical.iteritems():
                if(otherMsgs.has_key(kind)):
                    otherMsgs[kind] += count
                else:
                    otherMsgs[kind] = count
        return otherMsgs
    def getAverageNeighbors(self):
        nghSize = 0
        for node in self.itervalues():
            nghSize += len(node.neighbors)

        return float(nghSize) / len(self.itervalues())
    def getAverageSymmetricNeighbors(self):
        nghSize = 0
        for node in self.itervalues():
            nghSize += len(node.symmetricNeighbors)

        return float(nghSize) / len(self.itervalues())


class Simulation(dict):
    def __str__(self):
        return dict.__str__(self)
    __repr__ =  __str__
    def getCriticalStats(self, lowerTime, upperTime):
        totalDelivery = 0
        totalOverhead = 0
        count = 0
        for run in self.itervalues():
            d,o = run.getCriticalStats(lowerTime, upperTime)
            if(d != -1):
                totalDelivery += d
                totalOverhead += o
                count +=1
        if(count == 0):
            return -1, -1
        avgDelivery = totalDelivery / count
        avgOverhead = float(totalOverhead) / count
        return avgDelivery, avgOverhead
    def getTotalMessages(self):
        otherMsgs = { }
        runPerKind = { }
        for run in self.itervalues():
            for kind, count in run.getTotalMessages().iteritems():
                if(otherMsgs.has_key(kind)):
                    otherMsgs[kind] += count
                    runPerKind[kind] += 1
                else:
                    otherMsgs[kind] = count
                    runPerKind[kind] = 1
        for kind in otherMsgs:
            otherMsgs[kind] =  float(otherMsgs[kind]) / runPerKind[kind]
        return otherMsgs
    def getCostPerNeighbor(self,lowerTime,upperTime):
        average = 0
        stdDev = 0
        avgMin = 0
        avgMax = 0
        count = 0
        for run in self.itervalues():
            a,s,mi,ma = run.getCostPerNeighbor(lowerTime, upperTime)
            if(a != -1):
                average += a
                stdDev += s
                avgMin += mi
                avgMax += ma
                count += 1
        if(count == 0):
            return -1,-1,-1,-1
        return average / count, stdDev / count,float(avgMin)/ count, float(avgMax)/ count
    def getAverageNeighbors(self):
        nghSize = 0
        for run in self.itervalues():
            nghSize += run.getAverageNeighbors()

        return float(nghSize) / len(self.itervalues())
    def getAverageSymmetricNeighbors(self):
        nghSize = 0
        for run in self.itervalues():
            nghSize += run.getAverageSymmetricNeighbors()

        return float(nghSize) / len(self.itervalues())

    
runs = Simulation()
currentTime = -1

try:
    opts, args = getopt.getopt(sys.argv[1:], "a:v:d:f:g",['verbose'])
except getopt.GetoptError, e:
    # print help information and exit:
    print e
    usage()
    sys.exit(2)

dirName = ""
gnuplotFileName = "plot.dat"
graph = False
addFileName = ""
addValue = '-1'
verbose = False


for o,a in opts:
    if(o == "-d"):
        dirName = a
    elif(o == "-f"):
        gnuplotFileName = a
    elif(o == "-g"):
        graph = True
    elif(o == "-a"):
        addFileName = a
    elif(o == "-v"):
        addValue = a
    elif(o == "--verbose"):
        verbose = True

if(dirName != ""):
    files = os.listdir(dirName)
else:
    usage()
    sys.exit(2)

for fileName in files:
    if(fileName.find(".dat") != -1):
        inputFile = open(dirName + "/" + fileName, 'r')

        for line in inputFile:
            if(line.find('SIM') == -1 and line.find('Simulation')):
                timeString = line.split(' ')[1]
                currentTime = time2sec(timeString)
                
            if(line.find("Random seed") != -1):
                seed = int(line.split(' ')[4])
                runs[seed] = Run()
                nodes = runs[seed]
            elif(line.find("Time for mote") != -1):
                mote = line.split(' ')[4]
                nodes[mote] = Node(mote)
            elif(line.find("INIT:") != -1):
                mote = line.split(' ')[0].strip(':')
                role = line.split(' ')[6].strip('\n')
                nodes[mote].setRole(role)
            elif(line.find("Operation") != -1):                
                sender = line.split(' ')[0].strip(':')                
                kind = line.split(' ')[3]
                msgId = line[line.index("id:"):].split(" ")[0].strip(',').strip("id:")
                recipients = line[line.find("{")+1:line.find("}")].split()
                if(len(recipients) > 0):
                    nodes[sender].addMessage(Message(msgId, kind, recipients, currentTime))
            elif(line.find("Message received") != -1):
                recipient = line.split(' ')[0].strip(':')
                msgId = line[line.index("id:"):].split(" ")[0].strip(',').strip("id:")
                sender = line[line.index("from:"):].split(" ")[0].strip(',').strip("from:")
                if(msgId != 'NONE'):
                    try:
                        nodes[sender].msgReceived(msgId, recipient,currentTime)
                    except KeyError:
                        print seed, line
            elif(line.find("Message sent:") != -1):
                sender = line.split(' ')[0].strip(':')
                msgId = line[line.index("id:"):].split(" ")[0].strip(',').strip("id:")
                kind = line[line.index("type:"):].split(" ")[0].strip(',').strip("type:")
                nodes[sender].msgSent(msgId,kind)
            elif(line.find("Removing neighbor") != -1):
                mote = line.split(' ')[0].strip(':')
                neighbor = line.split(' ')[4]
                nodes[mote].removeNeighbor(neighbor)
            elif(line.find("All Neighbors") != -1):
                mote = line.split(' ')[0].strip(':')
                neighbors = line[line.find("{")+1:line.find("}")].split()
                nodes[mote].neighbors = neighbors
            elif(line.find("Symmetric Neighbors") != -1):
                mote = line.split(' ')[0].strip(':')
                neighbors = line[line.find("{")+1:line.find("}")].split()
                nodes[mote].symmetricNeighbors = neighbors


        inputFile.close()


# Print stats
gnuplotFile = open(gnuplotFileName,'w')
lowerTime = 0
upperTime = 0
for time in range(0, currentTime, 50):
#for time in range(400, 450, 50):
    lowerTime = upperTime
    #lowerTime = 350
    upperTime = time
    d,o = runs.getCriticalStats(lowerTime, upperTime)
    if(d != -1):
        avgNgh,devNgh,minNgh,maxNgh = runs.getCostPerNeighbor(lowerTime,upperTime)
        if(verbose):
            print "TIME (" + str(time) + "): delivery " + str(d) + " overhead " + str(o)
            print "Cost per message avg/devStd/min/max " + str(avgNgh) + "/" + str(devNgh)  + "/" + str(minNgh) + "/" + str(maxNgh)
        gnuplotFile.write(str(time) + "   " + str(d) + "   " + str(o) + "   " + str(avgNgh) + "   " + str(devNgh) + "   " + str(minNgh) + "   " + str(maxNgh) + '\n')
if(verbose):
    d,o = runs.getCriticalStats(0, currentTime)
    avgNgh,devNgh,minNgh,maxNgh = runs.getCostPerNeighbor(0,currentTime)
    print "TOTAL: delivery " + str(d) + " overhead " + str(o)
    print "Cost per message avg/devStd/min/max " + str(avgNgh) + "/" + str(devNgh)  + "/" + str(minNgh) + "/" + str(maxNgh)
    print "All messages " + str(runs.getTotalMessages())
    print "Neighbors:" + str(runs.getAverageNeighbors()) + " Symmetric Neighbors:" + str(runs.getAverageSymmetricNeighbors())

gnuplotFile.close()

if(addFileName != "" and addValue != '-1'):
    addFile = open(addFileName, 'a')
    d,o = runs.getCriticalStats(0, currentTime)
    avgNgh,devNgh,minNgh,maxNgh = runs.getCostPerNeighbor(0,currentTime)
    ## Super-hack per il problema con out_unreliable-grid-density_60-load_5-error_0-actuator_0.4
    if(d == -1):
        d = 0
        o = 0
    if(verbose):
        print "TOTAL: delivery " + str(d) + " overhead " + str(o)
        print "Cost per message avg/devStd/min/max " + str(avgNgh) + "/" + str(devNgh)  + "/" + str(minNgh) + "/" + str(maxNgh)
    addFile.write(addValue + "   " + str(d) + "   " + str(o) + "   " + str(avgNgh) + "   " + str(devNgh) + "   " + str(minNgh) + "   " + str(maxNgh)  + "   " + str(runs.getAverageNeighbors()) + "   " + str(runs.getAverageSymmetricNeighbors()) + '\n')
    addFile.close()

if(graph):
    g = Gnuplot.Gnuplot()
    g.title('A simple example') # (optional)
    g('set data style linespoints') # give gnuplot an arbitrary command
    g.xlabel('x')
    g.ylabel('y')
    g.plot(Gnuplot.File(gnuplotFileName, using='1:2',title='delivery'))
    raw_input('Please press return to continue...\n')
    g.plot(Gnuplot.File(gnuplotFileName, using='1:3'))
    raw_input('Please press return to continue...\n')

