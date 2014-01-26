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
select yn in "yes" "no"; do
	case $yn in
	yes) CREATE=true
	     ARRAY=()
	     break;;
	no)  break;;
	esac
done

# create $ARRAY from looped input.
while [[ $CREATE = true ]]
do
	select node in "add" "remove" "done"; do
	       	if [[ $node = "done" ]]; then
			break 2;

	       	elif [[ $node = "add" ]]; then
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
				echo -e "Container $ID exists.\nSuggested entry: $ID:$temp1 $temp3$temp4"
				select opt in "add" "local" "rename"; do
					if [[ $opt = "add" ]]; then
						ARRAY=("${ARRAY[@]}" "$ID:$temp1 $temp3$temp4")
						echo "$(printf '%s\n' "${ARRAY[@]}")"

						unset temp1
						unset temp2
						unset temp3
						unset temp4
						continue 4
					elif [[ $opt = "local" ]]; then
						ARRAY=("${ARRAY[@]}" "$ID:$temp1 Local")
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

			LOCATION=""
			echo "Set location of data"
			while [[ -z $LOCATION ]]
			do
				select LOCATION in "container" "local" "host"; do
					if [[ $LOCATION = "container" ]]; then
						LOCATION="Container"
					elif [[ $LOCATION = "local" ]]; then
						LOCATION="Local"
					elif [[  $LOCATION = "host" ]]; then
						LOCATION="Host"
					else
						echo "Invalid selection."
						continue
					fi
					break;
				done
			done

			if [[ $LOCATION = "Container" ]]; then
				echo -e "Container $ID does not exist.\nA data container will be created if needed."
                        fi
                        read -p "Directory: " DIR
			
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
			
     		elif [[ $node = "remove" ]]; then
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
