#!/bin/bash

MENU=$(sudo docker images | tr -s ' ' | cut -d ' ' -f1 | tail -n+2 | sort)
if [ -z $1 ]; then
	select IMAGE in `echo ${MENU[@]}`; do break; done
else
	IMAGE=$1
fi

MENU=$(sudo docker ps -a | tr -s ' '  | tr -s ' ' | rev | cut -d ' ' -f2 | rev | tail -n+2 | sort)
MENU=($MENU NONE)
if [[ ${#MENU[@]} -gt 1 ]]; then 
	if [ -z $2 ]; then
		echo "Mount volumes from container"
		select CONTAINER in `echo ${MENU[@]}`; do
			if [[ $CONTAINER = ${MENU[-1]} ]]; then
        		       CONTAINER=""
			fi
			break;
		done
	else
		CONTAINER=$2
	fi
fi

echo "Delete container on exit"
select yn in "yes" "no"; do
	if [[ $yn = "yes" ]]; then
		ARG="-t -i -rm"
	else
		ARG="-t -i"
	fi
	break;
done

CMD=/bin/bash
PATCH="sh -c"
PATCH2="exec >/dev/tty 2>/dev/tty </dev/tty && $CMD"

if [ -z $CONTAINER ]; then
	sudo docker run $ARG $IMAGE $PATCH "$PATCH2"
else
	sudo docker run $ARG -volumes-from $CONTAINER $IMAGE $PATCH "$PATCH2"
fi
