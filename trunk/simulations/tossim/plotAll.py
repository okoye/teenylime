#!/usr/bin/python

import sys
import getopt
import os
import math
import shutil
import re
from Numeric import *
import Gnuplot, Gnuplot.funcutils
from Scientific.Statistics import average, standardDeviation

def getErrorProbability(error):
    """Estimate packet error probabilty according to the formula given in TOSSIM manual"""
    E_b = float(error)
    d = 113
    S_s = (1 - E_b)**9
    S_e = (1 - E_b)**8 + (8*E_b * (1-E_b)**12)
    E_p = 1-(S_s*(S_e)**d)
    return E_p

def getDensity(size,side):
    side = (1/0.3)*side*0.001 # convert ft in km
    density = float(size) / (side*side)
    return density

def initGnuplot():
    gplot = Gnuplot.Gnuplot()
    gplot('set data style linespoints')
    gplot('set grid')
    gplot('set key below left')
    gplot('set terminal postscript enhanced color ')
    gplot('set xrange [0:0.944430562258]')
    
    return gplot

    
try:
    opts, args = getopt.getopt(sys.argv[1:], "d:p:",["no-plot"])
except getopt.GetoptError, e:
    # print help information and exit:
    print e
    usage()
    sys.exit(2)

parameterName = ""
noPlot = False

for o,a in opts:
    if(o == "-d"):
        dirName = a
    elif(o == '-p'):
        parameterName = a
    elif(o == '--no-plot'):
        noPlot = True
                

## Default Values
size = 100
seeds = 10
pars = [('density',48,'{/Symbol d}=%.0f nodes/km^2' % getDensity(size,60),'density (nodes/km^2)'), ('load',5,'{/Symbol l}=5 msg/min','background load (msgs/min)'), ('error',0.015,'{/Symbol e}=%.2f' % getErrorProbability(0.015),'message error rate'), ('actuator',0.4,'actuators=%.0f' % (0.4*size), 'actuators')]
outputDir = 'eps'
operations = ['out','rdg']
tags = ['unreliable', 'reliable']
topologies = ['grid', 'random']

def getTargetDir(op, tag, top, parameter):
    targetDir = op +'_' + tag + '-' + top
    for p in pars:
        targetDir += "-" + p[0] + "_"
        if(p[0] != parameter):
            targetDir += str(p[1])
        else:
            targetDir += "(.+)"
    targetDir += '$'
    return targetDir

def plotDelivery(title,dataFile, operation, tag, top, parameter):
    epsFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-delivery" + ".eps"
    pngFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-delivery" + ".png"
    g = initGnuplot()
    g.title(title)

    g('set output "' + epsFile + '"')

    label = tag + ", " + top + ' ('
    unreliableLabel = 'unreliable' + ", " + top + ' ('
    for p in pars:
        if(p[0] != parameter):
            label += p[2] + ", "
            unreliableLabel +=  p[2] + ", "
        else:
            xlabel = p[3]
    label = label[:-2] + ')'
    g.xlabel(xlabel)
    g.ylabel('delivery')
    g.plot(Gnuplot.File(dataFile, using='1:2',title=label))
    #g.plot(Gnuplot.File(dataFile, using='1:2',title=label),Gnuplot.File('eps/out_unreliable-grid-error.dat', using='1:2',title=unreliableLabel))
    

def plotOverhead(title,dataFile, operation, tag, top, parameter):
    epsFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-overhead" + ".eps"
    pngFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-overhead" + ".png"
    g = initGnuplot()
    g.title(title)

    g('set output "' + epsFile + '"')

    label = tag + ", " + top + ' ('
    for p in pars:
        if(p[0] != parameter):
            label += p[2] + ", "
        else:
            xlabel = p[3]
    label = label[:-2] + ')'
    g.xlabel(xlabel)
    g.ylabel('transmissions / message')
    g.plot(Gnuplot.File(dataFile, using='1:3',title=label))


def plotRecipient(title,dataFile, operation, tag, top, parameter):
    epsFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-recipient" + ".eps"
    pngFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter  +"-recipient" + ".png"
    g = initGnuplot()
    g.title(title)

    g('set output "' + epsFile + '"')

    label1 = tag + ", " + top + ' ('
    for p in pars:
        if(p[0] != parameter):
            label1 += p[2] + ", "
        else:
            xlabel = p[3]
    label1 = label1[:-2] + ')'
    label2 = "Standard Deviation"
    label3 = "min / max"
    g.xlabel(xlabel)
    g.ylabel('transmissions / recipient')
    g.plot(Gnuplot.File(dataFile, using='1:4',title=label1),Gnuplot.File(dataFile, using='1:4:($4+$5):($4-$5)',title=label2, with='errorbars 1'), Gnuplot.File(dataFile, using='1:4:6:7',title=label3, with='errorbars 3'))

def plotNeighbors(title,dataFile, operation, tag, top, parameter):
    epsFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-neighbors" + ".eps"
    pngFile = outputDir + "/" + op + '_' + tag + '-' + top + '-' + parameter + "-neighbors" + ".png"
    g = initGnuplot()
    g.title(title)

    g('set output "' + epsFile + '"')

    label1 = "Neighbors " + tag + ", " + top + ' ('
    label2 = "Symmetric Neighbors " + tag + ", " + top + ' ('
    for p in pars:
        if(p[0] != parameter):
            label1 += p[2] + ", "
            label2 += p[2] + ", "
        else:
            xlabel = p[3]
    label1 = label1[:-2] + ')'
    label2 = label2[:-2] + ')'
    g.xlabel(xlabel)
    g.ylabel('neighbors')
    g.plot(Gnuplot.File(dataFile, using='1:8',title=label1),Gnuplot.File(dataFile, using='1:9',title=label2))

if(os.path.exists(outputDir)):
    shutil.rmtree(outputDir)
os.mkdir(outputDir)

if(dirName != ""):
    dirs = os.listdir(dirName)

for parameterPair in pars:
    if(parameterName != ""):
        if(parameterName != parameterPair[0]):
            continue
    parameter = parameterPair[0]
    print "Generating graphs for " + parameter.upper() 
    for op in operations:
        for top in topologies:
            for tag in tags:
                print op.title(), top, tag, '[',
                gnuplotFileName = outputDir + '/' + op + '_' + tag + '-' + top + '-' + parameter + ".dat"
                toPlot = False
                values = []
                for d in dirs:
                    m = re.search(getTargetDir(op,tag,top,parameter),d)
                    if(m != None):
                        value = float(d[d.index(parameter):].split('-')[0].split('_')[1].strip('\n'))
                        values.append((value,d))
                if(len(values) > 1):
                    toPlot = True
                    values.sort()
                    for v in values:
                        print v[0],
                        sys.stdout.flush()
                        if(parameter == 'error'):
                            xvalue = getErrorProbability(v[0])
                        elif(parameter == 'density'):
                            xvalue = getDensity(size,v[0])
                        else:
                            xvalue = v[0]
                        os.system('./parseOutput.py -d ' + dirName + '/' + v[1] + ' -a ' + gnuplotFileName + ' -v ' + str(xvalue))
                print "]",
                if(toPlot and noPlot == False):
                    plotDelivery("Delivery " + op.upper() + " (%d nodes, %d seeds)" % (size, seeds), gnuplotFileName, op, tag, top, parameter)
                    plotOverhead("Overhead " + op.upper() + " (%d nodes, %d seeds)" % (size, seeds),gnuplotFileName, op, tag, top, parameter)
                    plotRecipient("Transmissions per recipient " + op.upper() + " (%d nodes, %d seeds)" % (size, seeds),gnuplotFileName, op, tag, top, parameter)
                    plotNeighbors("Neighbors " + op.upper() + " (%d nodes, %d seeds)" % (size, seeds),gnuplotFileName, op, tag, top, parameter)
                print "... done"
                
# Rotating Images
if(noPlot == False):
    print "Rotating images"
    os.chdir(outputDir)
    os.system('convertAll eps png -rotate 90')
    for f in os.listdir('.'):
        if(f.find(".eps") != -1):
            os.system('epstopdf ' + f)
