#!/bin/bash

mainFun(){
    echo -e "start to read configure"
    if [ `readConfigure` -eq 0 ];then
        echo -e "create jobs successfully"
    fi
    
}
deleteBlankJobConfigure(){ 
    for key in ${!jobmap[@]};do 
        if [[ -z ${jobmap[${key}]} ]];then
            unset jobmap[${key}]
        fi
    done
}
createWorkers(){
    for((i=0;i<$_n_arr;i++));  
    do    
        elem=${_arr[$i]}  
        echo "$i : $elem"  
    done
}
createWorkSpace(){

    if [ ! -x "s3transfer" ];then
        echo "no such file or directory:s3transfer"
        echo "please make 's3transfer' and this script in the same directory"
        return 1
    fi
    if [ ${defaultWorkSpaceID} -eq 0 ];then
        #use "s3transfer" as the first workspace
        createWorkers "s3transfer"
    done;   
    elif [ ];then


    fi

    for key in ${!jobmap[@]};do
        echo -e "$key\c"
    done 
    return 0
}
readConfigure(){
    declare -A jobmap=()
    declare -a workerArray=()
    IFS_old=$IFS
    IFS=$'\n'
    for line in `cat configure`
    do
        line=`echo $line | sed 's/[ \n]//g'`
        if [ -n "`echo ${line} | sed -n '/^\[.*]$/p'`" ];then
            if [ ${#jobmap[@]} -ne 0 ];then  
                deleteBlankJobConfigure
                if [ ! `createWorkSpace` -eq 0 ];then
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
            workerArray[${#workerArray[@]}]=value
        else
            key=`echo $line | cut -d "=" -f 1`
            value=`echo $line | cut -d "=" -f 2`
            jobmap[$key]=$value
        fi
    done
    if [ ${#jobmap[@]} -ne 0 ];then
        deleteBlankJobConfigure
        if [ ! `createWorkSpace` -eq 0 ];then
            return 1
        fi
        createWorkSpace
    fi
    IFS=$IFS_old
    return 0
}
defaultWorkSpaceIDPrefix="s3transfer-"
defaultWorkSpaceID=0
mainFun