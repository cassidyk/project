#build.sh
#!/bin/bash
# TODO:
# Vagrant	- enable alternate distro builds
# Package	- contain image with meta-data
# Install	- configure image state

# set $path
path=/home/user/project/build

# set $OUTPUT
OUTPUT=$path/image

if [ ! -d $OUTPUT ]; then
	mkdir $OUTPUT
fi

# create $MENU from scripts in /distro
BUILD=$(ls -1 $path/distro/ | sed 's/.sh//g')
MENU=($BUILD quit)

echo "Select a distro"
# create $DISTRO from $MENU selection
select distro in `echo ${MENU[@]}`; do
	if [[ ${MENU[-1]} = $distro ]]; then
		exit
	else
       		DISTRO=$distro
       		break;
	fi
done

# run build script for $DISTRO
sudo $path/distro/$DISTRO.sh base-$DISTRO

# save to /image and clean up
sudo docker save base-$DISTRO > $OUTPUT/base-$DISTRO.tar
sudo docker rmi base-$DISTRO
