!/bin/bash
# TODO:

# set $path
path=/home/user/project/build

# set $INPUT
INPUT=$path/node

# set $OUTPUT
OUTPUT=$path/repo

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

TAG=()
DIR=()
LOCATION=()
PERMISSION=()
for (( i=0; i < ${#VOLUME[@]}; i++ ))
do
	temp=$(echo ${VOLUME[$i]} | tr ":" " ")
	TAG=("${TAG[@]}" "${temp[0]}")
	DIR=("${DIR[@]}" "${temp[1]}")
	LOCATION=("${LOCATION[@]}" "${temp[2]}")
	PERMISSION=("${PERMISSION[@]}" "${temp[3]}")	
done

for (( i=0; i < ${#VOLUME[@]}; i++ ))
do
	echo ${VOLUME[$i]}
	echo ${TAG[$i]} ${DIR[$i]} ${LOCATION[$i]} ${PERMISSION[$i]}
done
