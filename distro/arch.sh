#!/bin/bash
# Generate a minimal filesystem for archlinux and load it into the local
# docker as "archlinux"
# requires root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ -z $1 ]; then
	read -p "Image name: " IMAGENAME
else
	IMAGENAME=$1
fi
set -e

PACSTRAP=$(which pacstrap)
[ "$PACSTRAP" ] || {
    echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
    exit 1
}
EXPECT=$(which expect)
[ "$EXPECT" ] || {
    echo "Could not find expect. Run pacman -S expect"
    exit 1
}

ROOTFS=~/rootfs-arch-$$-$RANDOM
mkdir $ROOTFS

#packages to ignore for space savings
PKGIGNORE=linux,jfsutils,lvm2,cryptsetup,groff,man-db,man-pages,mdadm,pciutils,pcmciautils,reiserfsprogs,s-nail,xfsprogs
 
expect <<EOF
set timeout 60
set send_slow {1 1}
spawn pacstrap -c -d -G -i $ROOTFS base haveged --ignore $PKGIGNORE
expect {
"Install anyway?" { send n\r; exp_continue }
"(default=all)" { send \r; exp_continue }
"Proceed with installation?" { send "\r"; exp_continue }
"skip the above package" {send "y\r"; exp_continue }
"checking" { exp_continue }
"loading" { exp_continue }
"installing" { exp_continue }
}
EOF

arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/Canada/Mountain /etc/localtime"
cat > $ROOTFS/etc/locale.gen <<DELIM
en_CA.UTF-8 UTF-8
en_CA ISO-8859-1
DELIM
arch-chroot $ROOTFS locale-gen
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = http://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# udev doesn't work in containers, rebuild /dev
DEV=${ROOTFS}/dev
mv ${DEV} ${DEV}.old
mkdir -p ${DEV}
mknod -m 666 ${DEV}/null c 1 3
mknod -m 666 ${DEV}/zero c 1 5
mknod -m 666 ${DEV}/random c 1 8
mknod -m 666 ${DEV}/urandom c 1 9
mkdir -m 755 ${DEV}/pts
mkdir -m 1777 ${DEV}/shm
mknod -m 666 ${DEV}/tty c 5 0
mknod -m 600 ${DEV}/console c 5 1
mknod -m 666 ${DEV}/tty0 c 4 0
mknod -m 666 ${DEV}/full c 1 7
mknod -m 600 ${DEV}/initctl p
mknod -m 666 ${DEV}/ptmx c 5 2

tar --numeric-owner -C $ROOTFS -c . | docker import - $IMAGENAME
docker run -rm $IMAGENAME echo Success.
rm -rf $ROOTFS
