#!/bin/bash
mainFun(){
    ps -ef | grep python > s3transfer-stop-tmp
    IFS_old=$IFS
    IFS=$'\n'
    for line in `cat s3transfer-stop-tmp`;do
        line=`echo $line | sed 's/[ ][ ]*/\t/g'`
        if [[ -n "`echo $line | sed -n '/.*master.*/p'`" || -n "`echo $line | sed -n '/.*worker.*/p'`" ]];then
            pid=`echo $line | cut -f 2`
            kill $pid
            echo "kill ${pid}"
        fi
    done
    IFS=$IFS_old
    rm -f s3transfer-stop-tmp
}
mainFun




