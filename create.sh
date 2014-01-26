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
MENU=$(ls -1 $INPUT)
MENU=($MENU quit)

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
	NODE=("${NODE[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / | cut -d " " -f1)")
	DIR=("${DIR[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / | cut -d " " -f2)")
	LOCATION=("${LOCATION[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / | cut -d " " -f3)")
	if [[ ${LOCATION[$i]} = "Host" ]]; then
		ACCESS=("${ACCESS[@]}" "$(echo ${VOLUME[$i]} | sed s/:/\ / | cut -d " " -f4)")	
	else
		ACCESS=("${ACCESS[@]}" nil)
	fi
done

CONTAINER=()
for (( i=0; i < ${#VOLUME[@]}; i++ ))
do
	test=$(sudo docker ps -a | tr -s ' ' | tr -s ' ' | rev | cut -d ' ' -f2 | rev | grep -o ^${NODE[$i]}$)

	if [[ ${LOCATION[$i]} = Local ]]; then
		CONTAINER=("${CONTAINER[@]}" "-v ${DIR[$i]}")
	elif [[ ${LOCATION[$i]} = Host ]]; then
		CONTAINER=("${CONTAINER[@]}" "-v ${DIR[$i]}:/host${DIR[$i]}:${ACCESS[$i]}")
	else
		CONTAINER=("${CONTAINER[@]}" "-volumes-from ${NODE[$i]}")

		if [[ -n $test ]]; then
			continue
		else
			if [[ -z $test ]]; then
				echo $test
				echo -e "${NODE[$i]} does not exist."
				select opt in "create" "quit"; do
					if [[ $opt = "quit" ]]; then
						exit
					else
						sudo docker run -v ${DIR[$i]} -name ${NODE[$i]} $BASE
						break;
					fi
				done
			fi
		fi
	fi
done
MOUNT=$(echo ${CONTAINER[@]})
echo $MOUNT
read -p "Image name: " NAME

sudo docker run $MOUNT -name $NAME $IMAGE /bin/bash
