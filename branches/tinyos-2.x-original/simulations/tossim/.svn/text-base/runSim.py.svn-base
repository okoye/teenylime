#!/usr/bin/python

import sys
import getopt
import os
import math
import shutil
import stat
from time import localtime,asctime,time

def usage():
    print """Usage: ./runSim.py -r NUM_RUN -t TIME -d DIRNAME -f LOSSY_FILE [-s START -e END] [-l load] [-a actuator_prob] [-g threshold --constant] [-p PARAM] [-v PAR_VALUE] [--reliable | --unreliable] [--seed] [-n size]"""


def pruneLossyFile(inputFileName, outputFileName, threshold):
    inputFile = open(inputFileName, 'r')
    outputFile = open(outputFileName, 'w')
    for line in inputFile:
        error = float(line.split(':')[2])
        if(error <= threshold):
            outputFile.write(line)
    inputFile.close()
    outputFile.close()

def constLossyFile(inputFileName, outputFileName, errorRate):
    inputFile = open(inputFileName, 'r')
    outputFile = open(outputFileName, 'w')
    for line in inputFile:
        error = float(line.split(':')[2])
        if(error < 0.04):
            lineList = line.split(':')
            lineList[2] = str(errorRate) + '\n'
            line = ":".join(lineList)
            outputFile.write(line)
    inputFile.close()
    outputFile.close()
                           
try:
    opts, args = getopt.getopt(sys.argv[1:], "p:r:f:d:t:v:s:e:l:g:a:n:",["reliable","unreliable","compile","constant","seed"])
except getopt.GetoptError, e:
    # print help information and exit:
    print e
    usage()
    sys.exit(2)

## Record initial time
startTime = time()

run = -1
lossyFile = ""
par = ""
parValue = -1
dirName = ""
timeSim = ""
reliable = False
unreliable = False
start = -1
end = -1
load = -1
recompile = False
compile_only = False
threshold = -1
constantError = False
actuator = -1
seed = False
size = 25

for o,a in opts:
    if(o == "-p"):
        par = a
        recompile = True
    elif(o == "-v"):
        parValue = int(a)
    elif(o == "-f"):
        lossyFile =  a
    elif(o == '-r'):
        run = int(a)
    elif(o == "-d"):
        dirName = a
    elif(o == "-t"):
        timeSim = int(a)
    elif(o == "-s"):
        start = int(a)
        recompile = True
    elif(o == "-e"):
        end = int(a)
        recompile = True
    elif(o == "-l"):
        load = int(a)
        recompile = True
    elif(o == "-a"):
        actuator = float(a)
        recompile = True
    elif(o == "-n"):
        size = int(a)
    elif(o == "-g"):
        threshold = float(a)
    elif(o == "--constant"):
        constantError = True
    elif(o == "--reliable"):
        reliable = True
    elif(o == "--unreliable"):
        unreliable = True
    elif(o == "--compile"):
        compile_only = True
    elif(o == "--seed"):
        seed = True



if(run == -1 or lossyFile == "" or dirName == ""):
    usage()
    sys.exit(2)


if(par != "" and parValue == -1):
    usage()
    sys.exit(2)

if(recompile):
    shutil.move("TLConstants.h", "TLConstants.orig")
    constants_h = open("TLConstants.h",'w')
    constants_orig = open("TLConstants.orig", 'r')
    for line in constants_orig:
        if(line.find("SIM_" + par.upper() + "_PROB") != -1):
            lineList = line.split(' ')
            prob = float(parValue) / 60
            lineList[2] = str(prob) + '\n'
            line = " ".join(lineList)
        elif(line.find("SIM_" + par.upper() + "_RELIABLE") != -1):
            if(reliable):
                lineList = line.split(' ')
                lineList[2] = "TRUE" + '\n'
                line = " ".join(lineList)
            elif(unreliable):
                lineList = line.split(' ')
                lineList[2] = "FALSE" + '\n'
                line = " ".join(lineList)
        elif(line.find("SIM_START") != -1 and start != -1):
            lineList = line.split(' ')
            lineList[2] = str(start) + '\n'
            line = " ".join(lineList)
        elif(line.find("SIM_END") != -1 and end != -1):
            lineList = line.split(' ')
            lineList[2] = str(end) + '\n'
            line = " ".join(lineList)
        elif(line.find("SIM_ACT_PROB") != -1 and actuator != -1):
            lineList = line.split(' ')
            lineList[2] = str(actuator)
            line = " ".join(lineList)
        elif(line.find("SIM_LOAD_PROB") != -1 and load != -1):
            lineList = line.split(' ')
            prob = float(load) / 60
            lineList[2] = str(prob) + '\n'
            line = " ".join(lineList)
        constants_h.write(line)
    constants_h.close()
    constants_orig.close()
    os.system('make -f Makefile.simulations pc')
    shutil.move("TLConstants.orig", "TLConstants.h")

## Post-process lossy-builder
if(threshold != -1):
    if(constantError):
        newLossyFile = lossyFile.split('/')[-1]
        newLossyFile = newLossyFile.split('.')[0] + "_constant-" + str(threshold) + "." + newLossyFile.split('.')[1]
        constLossyFile(lossyFile, "build/pc/" + newLossyFile, threshold)
        lossyFile = newLossyFile
    else:
        newLossyFile = lossyFile.split('/')[-1]
        newLossyFile = newLossyFile.split('.')[0] + "_" + str(threshold) + "." + newLossyFile.split('.')[1]
        pruneLossyFile(lossyFile, "build/pc/" + newLossyFile, threshold)
        lossyFile = newLossyFile
else:
    lossyFile = "../../" + lossyFile

os.chdir('build/pc')
if(seed):
    if(os.path.exists(dirName) == False):
        os.mkdir(dirName)
else:
    if(os.path.exists(dirName)):
        shutil.rmtree(dirName)
    os.mkdir(dirName)

if(compile_only):
    print "Executables main.exe and main.sh correctly generated in build/pc"
    main_sh = open('main.sh','w')
    main_sh.write('#!/bin/bash\n')
    main_sh.write('export DBG=usr3\n')
    main_sh.write('mkdir -p ' + dirName + '\n')
    main_sh.write('\n')
    for r in range(1, run+1):
        main_sh.write('time ./main.exe -b=1 -seed=' + str(r) + " -t=" + str(timeSim) + " -rf=" + str(lossyFile) + " " + str(size) + " > " + dirName + "/output-" + str(r) + ".dat\n")
    main_sh.close()
    os.chmod('main.sh',stat.S_IRWXU)
else:
    if(seed):
        print "Running " + 'time ./main.exe -b=1 -seed=' + str(run) + " -t=" + str(timeSim) + " -rf=" + str(lossyFile) + " " + str(size) + " > " + dirName + "/output-" + str(run) + ".dat"
        os.system('time ./main.exe -b=1 -seed=' + str(run) + " -t=" + str(timeSim) + " -rf=" + str(lossyFile) + " " + str(size) + " > " + dirName + "/output-" + str(run) + ".dat")
    else:
        for r in range(1, run+1):
            print "Running " + 'time ./main.exe -b=1 -seed=' + str(r) + " -t=" + str(timeSim) + " -rf=" + str(lossyFile) + " " + str(size) + " > " + dirName + "/output-" + str(r) + ".dat"
            os.system('time ./main.exe -b=1 -seed=' + str(r) + " -t=" + str(timeSim) + " -rf=" + str(lossyFile) + " " + str(size) + " > " + dirName + "/output-" + str(r) + ".dat")


## Print time statistics
## stopTime = time()
## print "Started at " + asctime(localtime(startTime))
## print "Finished at " + asctime(localtime(stopTime))
## print "Total lenght (s) %.0f" %(stopTime - startTime)
