#!/bin/bash
export DBG=usr3
RUN=3
TIME=2500
error=0.015
load=5
start=200
end=650
density=60
tag=reliable
actuator=0.4
topology=grid
operation=rdg
size=25

startingDate=`date`

if [ "$1" = "load" ];
    then
    make clean
    for tag in reliable unreliable; 
      do
      for load in 1 10 20 30 40 50 60
	do
	  #./runSim.py -r $RUN -t $TIME -d rdg_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -p RDG -v 1 --$tag -l $load -a $actuator -g $error -s $start -e $end
	   ./runSim.py -r $RUN -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -p $operation -v 1 --$tag  -l $load -a $actuator -g $error -s 200 -e 650
    # ./runSim.py -r $RUN -t $TIME -d trigger_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -p TRIGGER_CRITICAL -v 0.01 --$tag -l $load -a $actuator -g $error -s $start -e $end
      done
    done
elif [ "$1" = "actuator" ];
    then
    make clean
    for tag in reliable unreliable; 
      do
      for actuator in 0.1 0.2 0.4 0.6 0.8 1
	do
	  #./runSim.py -r $RUN -t $TIME -d rdg_$tag-$topology-density_$density-load_$load-error_$error -f scenarios/lossy-$size-$density-$topology.nss -p RDG -v 1 --$tag -l $load -a $actuator -g $error -s $start -e $end
	   ./runSim.py -r $RUN -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -p $operation -v 1 --$tag  -l $load -a $actuator -g $error -s 200 -e 650
    # ./runSim.py -r $RUN -t $TIME -d trigger-$tag-$topology-$density -f scenarios/lossy-$size-$density-$topology.nss -p TRIGGER_CRITICAL -v 0.01 --$tag -l $load -a $actuator -g $error -s $start -e $end
      done
    done

elif [ "$1" = "error" ];
    then
    density=40 # This is to have more neighbors
    for error in 0 0.005 0.01 0.015 0.02 0.025 0.03 0.035 0.04
      do
         ./runSim.py -r $RUN -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -g $error
    done
elif [ "$1" = "constant" ];
    then    
    density=40 # This is to have more neighbors
    for error in 0 0.005 0.01 0.015 0.02 # 0.025 0.03 0.035 0.04
      do
      ./runSim.py -r $RUN -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -g $error --constant
    done
elif [ "$1" = "cluster" ];
    then    
    density=48 # This is to have more neighbors
    size=100
    for error in 0 0.005 0.01 0.015 0.02 # 0.025 0.03 0.035 0.04
      do
      ./runSim.py -r $2 -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -n 100 -g $error --constant --seed
    done

elif [ "$1" = "density" ];
    then
    for density in 40 48 56 60 64 72 80
      do
        ./runSim.py -r $RUN -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -g $error
    done
    topology=random
    for density in 40 50 60 70 80
      do
        ./runSim.py -r $RUN -t $TIME -d $operation\_$tag-$topology-density_$density-load_$load-error_$error-actuator_$actuator -f scenarios/lossy-$size-$density-$topology.nss -g $error
    done
fi


finishingDate=`date`

echo Started $startingDate
echo Finished $finishingDate
