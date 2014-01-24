#!/bin/bash
# TODO:

# set $path
path=/home/user/project/build

# set $INPUT
INPUT=$path/node

# set $OUTPUT
OUTPUT=$path/repo

# set $BASE image
BASE="base-arch true"


# create $MENU from entries in $INPUT
NODE=$(ls -1 $INPUT)
MENU=($NODE quit)

echo "Select config"
select config in `echo ${MENU[@]}`; do
	if [[ ${MENU[-1]} = $config ]]; then
		exit;
	else
       		CONFIG=$config
       		break;
	fi
done

VOLUME=()
while read line
do
	if [[ $line = "IMAGE SOURCE" ]]; then
		context=$line
	elif [[ $line = "VOLUME" ]]; then
		context=$line

	elif [[ $context = "IMAGE SOURCE" ]]; then
		IMAGE=$line
		unset context
	elif [[ $context = "VOLUME" ]]; then
		VOLUME=("${VOLUME[@]}" "$line")
	fi
done < $INPUT/$CONFIG

NODE=()
DIR=()
LOCATION=()
ACCESS=()
for (( i=0; i < ${#VOLUME[@]}; i++ ))
do
	NODE=("${NODE[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / |cut -d " " -f1)")
	DIR=("${DIR[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / |cut -d " " -f2)")
	LOCATION=("${LOCATION[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / |cut -d " " -f3)")
	ACCESS=("${ACCESS[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / |cut -d " " -f4)")	
done

CONTAINER=()
for (( i=0; i < ${#VOLUME[@]}; i++ ))
do
	echo ${VOLUME[$i]}

	CONTAINER=("${CONTAINER[@]}" "-volumes-from ${NODE[$i]}")
	test=$(sudo docker ps -a | tr -s ' ' | cut -d ' ' -f9 | grep -o ^${NODE[$i]}$)
		
	if [[ ${LOCATION[$i]} = Local ]]; then
		if [[ -z $test ]]; then
			sudo docker run -v ${DIR[$i]} -name ${NODE[$i]} $BASE
		fi
	elif [[ ${LOCATION[$i]} = Host ]]; then
		if [[ -z $test ]]; then
			sudo docker run -v ${DIR[$i]}:${DIR[$i]}:${ACCESS[$i]} -name ${NODE[$i]} $BASE
		fi
	else
		if [[ -z $test ]]; then
			echo "Error: No container by name " ${NODE[$i]}
			exit
		fi
	fi
done

echo ${CONTAINER[@]}
