#!/bin/bash
# TODO:
# Currently checks if $ID is already a container but ignores any /node files that 
# have not yet been created

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
			test=$(sudo docker ps -a | tr -s ' ' | tr -s ' ' | rev | cut -d ' ' -f2 | rev | grep -o ^$ID$)
			while [[ -n $test ]]
			do
				temp1=$(sudo docker inspect $ID | grep -A 1 Volumes.: | sed -n '5 p' | tr -d ' ' | cut -d ':' -f1)
				temp2=$(sudo docker inspect $ID | grep -A 1 Volumes.: | sed -n '5 p' | tr -d ' ' | cut -d ':' -f2)

				temp1=$(echo $temp1 | sed 's/"//g')
				temp2=$(echo $temp2 | sed 's/"//g')
				
				if [[ $temp1 = $temp2 ]]; then
					temp3="Host"
					temp4=$(sudo docker inspect $ID | grep $temp1 | sed -n '3 p' | tr -d ' ' | cut -d ':' -f2)
					if [[ $temp4 = true ]]; then
						temp4=" RW"
					else
						temp4=" RO"
					fi
				else
					temp3="Container"
				fi
				echo -e "Container name: $ID already exists.\nUse: $ID:$temp1 $temp3$temp4"
				select opt in "Yes" "No"; do
					if [[ $opt = "Yes" ]]; then
						ARRAY=("${ARRAY[@]}" "$ID:$temp1 $temp3$temp4")
						echo "$(printf '%s\n' "${ARRAY[@]}")"

						unset temp1
						unset temp2
						unset temp3
						unset temp4
						continue 4
					else
						unset temp1
						unset temp2
						unset temp3
						unset temp4

						read -p "Enter new ID: " ID
						break
					fi
				done
			done

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
			if [[  $LOCATION = "Host"  ]]; then
				echo "Set volume permission"
				while [[ -z $PERMISSION ]]
				do
					select PERMISSION in "RW" "RO"; do
						PERMISSION=" $PERMISSION"
						break;
					done
				done
			fi

			ARRAY=("${ARRAY[@]}" "$ID:$DIR $LOCATION$PERMISSION")
			
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

cat $OUTPUT/$FILE | awk '!a[$0]++' > $OUTPUT/temp
mv $OUTPUT/temp $OUTPUT/$FILE
