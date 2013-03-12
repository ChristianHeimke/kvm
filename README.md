# kvm tools


## create_vm.sh

This script will create a new VM based on a basesystem which must exists as LVM volume.
To use this script you have to install the VMM script and have set up the base system. The script has been tested with debian linux 6.0.7.

Usage:
> create_vm.sh ip=127.0.0.1 name=evilroot [size=100G] [mem=1024] [cpu=1]