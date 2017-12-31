declare -A jobmap=()

fun(){
    return 0
}

if [[ `fun` -eq 0 ]];then
    echo "ss"
fi

fun
if [[ $? -eq 0 ]];then
    echo "kk"
fi