#!/bin/bash

printHelp(){
    echo -e "to use start_workers,you must use the following options"
    echo -e "\t-h\tshow this documnet"
    echo -e "\t-n\tset the number of workers"
}
startWorkers(){
    
    workerList=`ls -d */`
    for var in $workerList
    do
        if [ ${var:0:2} != "server" ]
        then
            nohup python ${var}worker.py>/dev/zero 2>&1  & 
        fi
    done

}


if [[ $# -eq 0 || $1 = "-h" ]]
then
    printHelp
elif [ $1 = "-n" ]
then
    if [ $# -eq 1 ]
    then
        echo -e "you must set the number of workers to start"
    else
        tmp=`echo $2|sed 's/[0-9]//g'` 
        if [ -z tmp ]
        then
            echo -e "the para following '-n' must be an integer"
        else 
            startWorkers
        fi
    fi
fi
