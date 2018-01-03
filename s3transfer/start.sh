#!/bin/bash
mainFun(){
    echo -e "start to read configure"
    readConfigure
    if [ $? -eq 0 ];then
        echo -e "create jobs successfully"
    fi
}
configureWorker(){
    port=`echo ${1} | cut -d ":" -f 2`
    isContinue=`echo ${1} | cut -d ":" -f 3`
    for line in `cat "s3transfer/src/server/config-worker"`;do
        if [[ -z $line || -n "`echo $line | sed -n '/^#.*/p'`" || `echo $line | grep -o '=' | wc -l` -ne 1 ]];then
            echo ${line} >> "worker-config-tmp"
            continue
        fi
        line=`echo $line | sed 's/[ \n]//g'`
        key=`echo $line | cut -d "=" -f 1`
        if [[ -n ${key} && ${key} = "port" && -n ${port} ]];then
            echo "port = ${port}" >> "worker-config-tmp"
        elif [[ -n ${key} && ${key} = "is-continue" && -n ${isContinue} ]];then
            echo "is-continue = ${isContinue}" >> "worker-config-tmp"
        else
            echo ${line} >> "worker-config-tmp"
        fi
    done
    rm "${workerPath}/config-worker"
    mv -f "worker-config-tmp" "${workerPath}/config-worker"
    echo "create server-${i} success, port:${port}, is-continue:${isContinue}"
}
createWorkers(){
    for((i=0;i<${#workerArray[@]};i++));do
        workerPath="${workSpaceName}/src/server-${i}"
        if [ ! -x ${workerPath} ];then
            cp -r "s3transfer/src/server" ${workerPath}
        fi
        configureWorker ${workerArray[i]}
        python ${workerPath}/worker.py &
        echo "start server-${i} success"
    done
}
configureMaster(){
    let isDealedWorker=0
    for line in `cat s3transfer/src/client/config-master`;do
        if [[ -z $line || -n "`echo $line | sed -n '/^#.*/p'`" || `echo $line | grep -o '=' | wc -l` -ne 1 ]];then
            echo ${line} >> config-master-tmp
            continue
        fi
        line=`echo $line | sed 's/[ \n]//g'`
        key=`echo $line | cut -d "=" -f 1`
        if [ -n "${jobmap[${key}]}" ];then
            echo "${key} = ${jobmap[$key]}" >> config-master-tmp
            echo "${key} = ${jobmap[$key]}"
        elif [[ ${key} = "worker" ]];then
            if [ ${isDealedWorker} -eq 1 ];then
                continue
            fi
            for worker in ${workerArray[@]};do
                ip=`echo ${worker} | cut -d ":" -f 1`
                port=`echo ${worker} | cut -d ":" -f 2`
                echo "${key} = ${ip}:${port}" >> config-master-tmp
            done
            let isDealedWorker=1
        else
            echo ${line} >> config-master-tmp
        fi
    done
    rm ${workSpaceName}/src/client/config-master
    mv -f config-master-tmp ${workSpaceName}/src/client/config-master
}
createMaster(){
    if [ ! -x ${workSpaceName} ];then
        cp -r s3transfer ${workSpaceName}
        rm -rf "${workSpaceName}/src/server"
    fi
    configureMaster
    echo "create master success"
}
createWorkSpace(){
    if [ ! -x "s3transfer" ];then
        echo "no such file or directory:s3transfer"
        echo "please make 's3transfer' and this script in the same directory"
        return 1
    fi
    workSpaceName="${defaultWorkSpaceIDPrefix}${defaultWorkSpaceID}"
    echo "start to create workspace:${workSpaceName}, job-ID: ${jobmap["job-ID"]}"
    createMaster
    createWorkers
    python ${workSpaceName}/src/client/master.py &
    echo "start master success"
    let defaultWorkSpaceID+=1
    return 0
}
readConfigure(){
    declare -A jobmap=()
    declare -a workerArray=()
    IFS_old=$IFS
    IFS=$'\n'
    for line in `cat configure`;do
        line=`echo $line | sed 's/[ \n]//g'`
        if [ -n "`echo ${line} | sed -n '/^\[.*]$/p'`" ];then
            if [ ${#jobmap[@]} -ne 0 ];then  
                createWorkSpace
                if [ ! $? -eq 0 ];then
                    return 1
                fi
            fi
            jobmap=()
            workerArray=()
            jobmap["job-ID"]=`echo $line | sed 's/[]\[]//g'`
            continue
        fi
        if [[ -z $line || -n "`echo $line | sed -n '/^#.*/p'`" || `echo $line | grep -o '=' | wc -l` -ne 1 ]];then
            continue
        elif [[ -n "`echo $line | sed -n '/^worker.*/p'`" ]];then
            value=`echo $line | cut -d "=" -f 2`
            workerArray[${#workerArray[@]}]=${value}
        else
            key=`echo $line | cut -d "=" -f 1`
            value=`echo $line | cut -d "=" -f 2` 
            if [[ -n ${key} && -n ${value} ]];then
                jobmap[${key}]=${value}
            fi
        fi
    done
    if [ ${#jobmap[@]} -ne 0 ];then
        createWorkSpace
        if [ ! $? -eq 0 ];then
            return 1
        fi
    fi
    IFS=$IFS_old
    return 0
}
screenName="s3transfer-screen"
defaultWorkSpaceIDPrefix="s3transfer-"
defaultWorkSpaceID=0
mainFun