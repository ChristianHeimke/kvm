#!/bin/bash
#title         	:reate_vm.sh
#description   	:This script will clone an existing basesystem and set up the 
#				 network and hostname
#author		 	:Christian Heimke
#date          	:2013-03-12
#version       	:0.1    
#usage		 	:bash create_vm.sh ip=127.0.0.1 name=evilroot [size=100G] [mem=1024] [cpu=1]
#notes         	:you have to install the vmm script and a base system as 
#					 LVM volume
#==============================================================================


# script settings
PREFIX="/Users/cheimke/mnt/"
KVM="/Users/cheimke/mnt/etc/kvm/"
EXPECTED_ARGS=2

# vm settings
NAME="evilroot"
IP="127.0.0.1"
SIZE="100G"
MEM="1024"
CPU="1"
ID="0"

########################################################
#
#	set_kvm <name> <ip> <mem> <cpu> <port>
#
########################################################
function set_kvm {

echo "name=$1
mem=$3
smp=$4

host=10.100.100.1
port=112$5
monitor=telnet:$host:$port,server,nowait,nodelay
vnc=10.100.100.1:$5

netdriver=virtio

tap_wan_macaddr=00:23:42:23:42:$5
tap_wan_name=$1_wan
tap_wan_route1=\"$2/32 dev $1_wan\"

hda1=/dev/vg0/$1,cache=none,if=virtio,boot=on
boot=c" > $KVM/$1
}

########################################################
#
#	set_network
#
########################################################
function set_network {

echo "auto lo
	iface lo inet loopback

	auto eth0
	iface eth0 inet static
	  address $1
	  netmask 255.255.255.255
	  broadcast 255.255.255.255
	  up route add -host 78.47.2.165 dev eth0
	  up ip route add default via 78.47.2.165" > $PREFIX/etc/network/interfaces
}

########################################################
#
#	set_udev
#
########################################################
function set_udev {
	echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"00:23:42:23:42:$1\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth0\"" > $PREFIX/etc/udev/rules.d/70-persistent-net.rules
}

########################################################
#
#	set_hostname
#
########################################################
function set_hostname {
	echo $1 > $PREFIX/etc/hostname
}

########################################################
#
#	set_nameserver
#
########################################################
function set_nameserver {
	echo "nameserver 8.8.8.8" > $PREFIX/etc/resolv.conf
}

########################################################
#
#	MAIN
#
########################################################

# usage
if [ $EXPECTED_ARGS -gt $# ]
then
  echo "Usage: create_vm.sh ip=127.0.0.1 name=evilroot [size=100G] [mem=1024] [cpu=1]"
  echo ".... ip = ip of the vm"
  echo ".... name = name of the vm"
  echo ".... size = size of the lvm volume, default 100G, optional"
  echo ".... mem = memory of the vm, default 1024M, optional"
  echo ".... cpu = number of cpu, default 1, optional"
  exit -1
fi

# split parameters and put them into the vars
args=("$@")
for ((i = 0; i <= $#; i++)); do
	string=${args[$i]}

	variable=$(echo "$string" | cut -d'=' -f1)
	value=$(echo "$string" | cut -d'=' -f2-)

	case "$variable" in

		"name") echo "setting name to.... $value";
		    	NAME="$value"
		    ;;
		"ip")  	echo  "setting ip to.... $value"
		    	IP="$value"
		    ;;
		"size") echo  "setting size to.... $value"
		    	SIZE="$value"
		    ;;
		"mem")  echo  "setting memory to.... $value"
		    	MEM="$value"
		    ;;
		"cpu")  echo  "setting cpu to.... $value"
		    	CPU="$value"
		    ;;
		*) 
		   ;;
		esac

done

# get the last number of the IP address to use as ID
eval $(echo "$IP" | awk '{print "IP1="$1";IP2="$2";IP3="$3";IP4="$4}' FS=.)
ID="$IP4"

# create lvm snapshot
`/sbin/lvcreate -L $SIZE -s -n $NAME /dev/vg0/basesystem`
# get the partition
`/sbin/kpartx -a /dev/vg0/$NAME`

# mount the 1st partition
`/bin/mount /dev/mapper/vg0-${NAME}1 $PREFIX`

# make the config valid
set_kvm $NAME $IP $MEM $CPU $ID
set_network $IP
set_udev $ID
set_hostname $NAME
set_nameserver

# umount
`/bin/umount /mnt/lvm`

# remove kpartx stuff
`/sbin/kpartx -d /dev/vg0/$NAME`

# start vm
`/etc/init.d/vmm start $NAME`