#!/bin/bash
# TODO:

# set $path
path=/home/user/project/build

# set $OUTPUT
OUTPUT=$path/node

# create $MENU from archives in /image
MOUNT=$(ls -1 $path/image | sed 's/.tar//g')
MENU=($MOUNT quit)

echo "Select an image"
# create $IMAGE from $MENU selection
select image in `echo ${MENU[@]}`; do
	if [[ ${MENU[-1]} = $image ]]; then
		exit
	else
       		IMAGE=$image
       		break;
	fi
done

echo "Create volume node?"
select yn in "Yes" "No"; do
	case $yn in
	Yes) CREATE=true
	     ARRAY=()
	     break;;
	No)  break;;
	esac
done

# create $ARRAY from looped input.
while [[ $CREATE = true ]]
do
	select node in "Add node" "Remove node" "Done"; do
	       	if [[ $node = "Done" ]]; then
			break 2;

	       	elif [[ $node = "Add node" ]]; then
			read -p "ID: " ID
			read -p "Directory: " DIR
			
			LOCATION=""
			echo "Set location of data"
			while [[ -z $LOCATION ]]
			do
				select LOCATION in "Container" "Local" "Host"; do
					break;
				done
			done

			PERMISSION=""
			echo "Set volume permission"
			while [[ -z $PERMISSION ]]
			do
				select PERMISSION in "RW" "RO"; do
					break;
				done
			done

			ARRAY=("${ARRAY[@]}" "$ID:$DIR $LOCATION $PERMISSION")
			
     		elif [[ $node = "Remove node" ]]; then
			select remove in "${ARRAY[@]}"; do
				for (( i=0; i < ${#ARRAY[@]}; i++ ))
				do
					if [[ "${ARRAY[$i]}" = "$remove" ]]; then
						echo "Remove: ${ARRAY[$i]}"
						continue;
					fi
					temp=("${temp[@]}" "${ARRAY[$i]}")
				done
				ARRAY=("${temp[@]}")
				unset temp
				break; 
			done
		fi
		break;
	done

	echo "$(printf '%s\n' "${ARRAY[@]}")"
done

read -p "Enter filename: " FILE
while [ -f $OUTPUT/$FILE ]
do
	read -p "File exists. Enter filename: " FILE
done

echo "IMAGE SOURCE" > $OUTPUT/$FILE
echo $IMAGE >> $OUTPUT/$FILE

if [[ $CREATE = true ]]; then
	echo -e "\nVOLUME" >> $OUTPUT/$FILE
	echo "$(printf '%s\n' "${ARRAY[@]}")" >> $OUTPUT/$FILE
fi
