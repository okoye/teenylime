#!/bin/bash
RUN=3
TIME=1500
error=0.015
load=5
start=200
end=650
tag=reliable
actuator=0.4
density=40
topology=grid
operation=RDG

./runSim.py -r $RUN -t $TIME  -d foo -f scenarios/lossy-25-$density-$topology.nss -s $start -e $end -l $load -a $actuator -g $error -p $operation -v 1 --$tag --compile
