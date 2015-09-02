#!/bin/bash
clear

#v0.09

#Copyright (C) 2015 Clavister AB
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
        echo "sudo $0 <Clavister img>"
  exit
fi

if [ "$#" -ne 1 ]
then
  echo "Usage: sudo $0 <Clavister img>"
  exit 1
fi

while [ answer != "x" ]
do
clear
echo "Select from the following functions"
echo '  x    exit'
echo '  1    Setup cOS Core'
echo '  2    Setup cOS Stream'
read -p " ?" answer
    case $answer in
       x) break ;;

1)
echo "Please type in the security gateway name"
echo -n "This will also be the name of the XML file :"
read name
echo " "
Dist=$(cat /etc/*-release | grep debian)
if [ -z "$Dist" ]; then
	emu1=$(whereis qemu-kvm | awk '{ print $3}')
	emu2=$(whereis qemu-system-x86_64 | awk '{ print $3}')
	emu3=$(whereis kvm-spice | awk '{ print $3}')
		if [ "${emu1}" != "" ]; then
        	emu=$emu1
	        elif [ "${emu2}" != "" ]; then
        	emu=$emu2
        	elif [ "${emu3}" != "" ]; then
        	emu=$emu3
        	fi
	else
	emu1=$(which qemu-system-x86_64 | awk '{ print $1}')
	emu2=$(which qemu-kvm | awk '{ print $1}')
	emu3=$(which kvm-spice | awk '{ print $1}')
		if [ "${emu1}" != "" ]; then
        	emu=$emu1
        	elif [ "${emu2}" != "" ]; then
        	emu=$emu2
        	elif [ "${emu3}" != "" ]; then
        	emu=$emu3
        	fi
fi

###### User choice between openswitch or bridge-utilities ##############
echo "Is this setup going to use OpenvSwitch or Bridge-utilities "
        echo "1) Bridge-utilities"
        echo "2) OpenvSwitch"
                echo -n "Enter Choice:"
                read -e input
                if [[ $input = '1' ]]; then
		#### jump to openswitch###
	
echo "##################################################################################################"
echo "Clavister Virtual Security Gateway uses three pre-configured virtual interfaces, If1, If2 and If3.
Virtual interfaces must be mapped to Linux bridges or physical adapters.
Please refer to the KVM manual for physical adapters or adapters in SR-IOV mode."
echo "##################################################################################################"
echo " "

brctl_check=$(brctl show | awk '{ print $1 }' | awk '{if(NR>1)print}')
if [ -z "$brctl_check" ]; then
	echo "No Bridge found Aborting Setup in 5 sec "
	echo "Please download and install bridge-utils"
	sleep 5
	exit 1
	else
	echo "The following bridges were found"
fi

echo ""
brctl show | awk '{ print $1 }' | awk '{if(NR>1)print}' > brctl
filename=./brctl
count=$(cat $filename | wc -l)
declare -a array1
array1=( `cat "$filename"`)
nr=0
for i in $(eval echo "{1..$count}")
        do
br_iface=${array1[$nr]}
echo "Bridge interface: " $br_iface
nr=$(($nr + 1))
array10=${array1[0]}
array11=${array1[1]}
array12=${array1[2]}
done
if [ -z "$array11" ] && [ -z "$array12" ]; then
	array11=${array1[0]}
	array12=${array1[0]}
fi
if [ -z "$array12" ]; then
	array12=${array1[1]}
fi
	
echo ""
echo "This is the default mapping."
echo "Virtual security gateway network interface        Bridge map"
echo "                                  If1<------------->$array10"
echo "                                  If2<------------->$array11"
echo "                                  If3<------------->$array12"
echo " "
echo "Do you want to add them in that order? "
	echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
                echo -n "Virtual security gateway If1 bridge: "
		read array10
		echo -n "Virtual security gateway If2 bridge: "
		read array11
		echo -n "Virtual security gateway If3 bridge: "
		read array12
		echo "This mapping was created"
		echo "Virtual security gateway network interface        Bridge map"
		echo "                                  If1<------------->$array10"
		echo "                                  If2<------------->$array11"
		echo "                                  If3<------------->$array12"
		else [[ $input = 'y' ]];
        fi

emu1=$(whereis qemu-kvm | awk '{ print $2}')
emu2=$(whereis qemu-system-x86_64 | awk '{ print $2}')
emu3=$(whereis kvm-spice | awk '{ print $2}')
if [ "${emu1}" != "" ];	then
        emu=$emu1
        elif [ "${emu2}" != "" ]; then
	emu=$emu2
	elif [ "${emu3}" != "" ]; then
	emu=$emu3
	fi

echo "Emulator: "$emu
source_file=$(pwd)
echo "Path: "$source_file
machine=pc
echo "Machine: "$machine
echo " "
echo "Is The Above Information Correct? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
		exit 1
                else [[ $input = 'y' ]];
        fi


echo "<domain type='kvm' id='34'>
  <name>$name</name>
  <memory unit='KiB'>262144</memory>
  <currentMemory unit='KiB'>262144</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='$machine'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>$emu</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw' cache='none' io='native'/>
      <source file='$source_file/$1'/>
      <target dev='hda' bus='ide'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <source bridge='$array10'/>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x13' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array11'/>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array12'/>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </interface>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='$port' autoport='no' listen='$ip'>
      <listen type='address' address='$ip'/>
    </graphics>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </memballoon>
  </devices>
</domain>" > ./$name.xml
rm -rf ./brctl
echo ""
echo "Xml file for the new Virtual Security GW has been generated"

echo "Do you want to add security gateway to KVM? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
		define=$(virsh define $name.xml)
                else [[ $input = 'n' ]];
		echo "You need to define the $name.xml with virsh yourself"
	exit 1
        fi
echo $define
if [ -z "$define" ]; then
	echo " "
	else
	echo "Do you want to start the security gateway? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
                Start=$(virsh start $name)
		echo "Security gatway started"
                else [[ $input = 'n' ]];
                echo " "
		fi	
	fi
	exit 1
###############Open vSwitch config###########################
	else [[ $input = '2' ]];
echo "##################################################################################################"
echo "Clavister Virtual Security Gateway uses three pre-configured virtual interfaces, If1, If2 and If3.
Virtual interfaces must be mapped to Linux bridges or physical adapters.
Please refer to the KVM manual for physical adapters or adapters in SR-IOV mode."
echo "##################################################################################################"
echo " "

Openvswitch=$(lsmod | grep openvswitch | awk '{if(NR<2)print}')
if [ -z "$Openvswitch" ]; then
        echo "No Bridge found Aborting Setup in 5 sec "
        echo "Please download and install openvswitch"
        sleep 5
        exit 1
        else
        echo ""
	fi

echo ""

Vhost_net=$(lsmod | grep vhost_net | awk '{ print $1 }' | awk '{if(NR<2)print}')
if [ -z "$Vhost_net" ]; then
	echo "vhost_net modual not loaded"
	echo "attempting to load modual"
	modprobe vhost_net
	sleep 2
fi
Vhost_net=$(lsmod | grep vhost_net | awk '{ print $1 }' | awk '{if(NR<2)print}')
if [ -z "$Vhost_net" ]; then
	echo "vhost_net modual not loaded"
	echo "Aborting Setup"
	else
	echo "vhost_net modual loaded"
fi
echo ""
echo "The following bridges were found"
ovs-vsctl list-br | awk '{ print $1 }' | awk '{if(NR>0)print}' > openvswitch
filename=./openvswitch
count=$(cat $filename | wc -l)
declare -a array1
array1=( `cat "$filename"`)
nr=0
for i in $(eval echo "{1..$count}")
        do
br_iface=${array1[$nr]}
echo "Bridge interface: " $br_iface
nr=$(($nr + 1))
array10=${array1[0]}
array11=${array1[1]}
array12=${array1[2]}
done
if [ -z "$array11" ] && [ -z "$array12" ]; then
        array11=${array1[0]}
        array12=${array1[0]}
fi
if [ -z "$array12" ]; then
        array12=${array1[1]}
fi

echo ""
echo "This is the default mapping."
echo "Virtual security gateway network interface        Bridge map"
echo "                                  If1<------------->$array10"
echo "                                  If2<------------->$array11"
echo "                                  If3<------------->$array12"
echo " "
echo "Do you want to add them in that order? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
                echo -n "Virtual security gateway If1 bridge: "
                read array10
                echo -n "Virtual security gateway If2 bridge: "
                read array11
                echo -n "Virtual security gateway If3 bridge: "
                read array12
                echo "This mapping was created"
                echo "Virtual security gateway network interface        Bridge map"
                echo "                                  If1<------------->$array10"
                echo "                                  If2<------------->$array11"
                echo "                                  If3<------------->$array12"
                else [[ $input = 'y' ]];
        fi

echo "Emulator: "$emu
source_file=$(pwd)
echo "Path: "$source_file
machine=pc
echo "Machine: "$machine
echo " "
echo "Is The Above Information Correct? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
                exit 1
                else [[ $input = 'y' ]];
        fi

echo "<domain type='kvm' id='34'>
  <name>$name</name>
  <memory unit='KiB'>262144</memory>
  <currentMemory unit='KiB'>262144</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='$machine'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>$emu</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw' cache='none' io='native'/>
      <source file='$source_file/$1'/>
      <target dev='hda' bus='ide'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <source bridge='$array10'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x13' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array11'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array12'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </interface>
    <input type='mouse' bus='ps2'/>
    <graphics type='vnc' port='$port' autoport='no' listen='$ip'>
      <listen type='address' address='$ip'/>
    </graphics>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </memballoon>
  </devices>
</domain>" > ./$name.xml

rm -rf ./openvswitch
echo ""
echo "Xml file for the new Virtual Security GW has been generated"

echo "Do you want to add security gateway to KVM? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
                define=$(virsh define $name.xml)
                else [[ $input = 'n' ]];
                echo "You need to define the $name.xml with virsh yourself"
        exit 1
        fi
echo $define
if [ -z "$define" ]; then
        echo " "
        else
        echo "Do you want to start the security gateway? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
                Start=$(virsh start $name)
                echo "Security gatway started"
                else [[ $input = 'n' ]];
                echo " "
                fi



	fi
fi
;;

2)
echo "Please type in the security gateway name"
echo -n "This will also be the name of the XML file :"
read name
echo " "
Dist=$(cat /etc/*-release | grep debian)
if [ -z "$Dist" ]; then
	emu1=$(whereis qemu-kvm | awk '{ print $3}')
	emu2=$(whereis qemu-system-x86_64 | awk '{ print $3}')
	emu3=$(whereis kvm-spice | awk '{ print $3}')
		if [ "${emu1}" != "" ]; then
        	emu=$emu1
	        elif [ "${emu2}" != "" ]; then
        	emu=$emu2
        	elif [ "${emu3}" != "" ]; then
        	emu=$emu3
        	fi
	else
	emu1=$(which qemu-system-x86_64 | awk '{ print $1}')
	emu2=$(which qemu-kvm | awk '{ print $1}')
	emu3=$(which kvm-spice | awk '{ print $1}')
		if [ "${emu1}" != "" ]; then
        	emu=$emu1
        	elif [ "${emu2}" != "" ]; then
        	emu=$emu2
        	elif [ "${emu3}" != "" ]; then
        	emu=$emu3
        	fi
fi

###### User choice between openswitch or bridge-utilities ##############
echo "Is this setup going to use OpenvSwitch or Bridge-utilities "
        echo "1) Bridge-utilities"
        echo "2) OpenvSwitch"
                echo -n "Enter Choice:"
                read -e input
                if [[ $input = '1' ]]; then
		#### jump to openswitch###
	
echo "##################################################################################################"
echo "Clavister Virtual Security Gateway uses three pre-configured virtual interfaces, If1, If2 and If3.
Virtual interfaces must be mapped to Linux bridges or physical adapters.
Please refer to the KVM manual for physical adapters or adapters in SR-IOV mode."
echo "##################################################################################################"
echo " "

brctl_check=$(brctl show | awk '{ print $1 }' | awk '{if(NR>1)print}')
if [ -z "$brctl_check" ]; then
	echo "No Bridge found Aborting Setup in 5 sec "
	echo "Please download and install bridge-utils"
	sleep 5
	exit 1
	else
	echo "The following bridges were found"
fi

echo ""
brctl show | awk '{ print $1 }' | awk '{if(NR>1)print}' > brctl
filename=./brctl
count=$(cat $filename | wc -l)
declare -a array1
array1=( `cat "$filename"`)
nr=0
for i in $(eval echo "{1..$count}")
        do
br_iface=${array1[$nr]}
echo "Bridge interface: " $br_iface
nr=$(($nr + 1))
array10=${array1[0]}
array11=${array1[1]}
array12=${array1[2]}
done
if [ -z "$array11" ] && [ -z "$array12" ]; then
	array11=${array1[0]}
	array12=${array1[0]}
fi
if [ -z "$array12" ]; then
	array12=${array1[1]}
fi
	
echo ""
echo "This is the default mapping."
echo "Virtual security gateway network interface        Bridge map"
echo "                                  If1<------------->$array10"
echo "                                  If2<------------->$array11"
echo "                                  If3<------------->$array12"
echo " "
echo "Do you want to add them in that order? "
	echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
                echo -n "Virtual security gateway If1 bridge: "
		read array10
		echo -n "Virtual security gateway If2 bridge: "
		read array11
		echo -n "Virtual security gateway If3 bridge: "
		read array12
		echo "This mapping was created"
		echo "Virtual security gateway network interface        Bridge map"
		echo "                                  If1<------------->$array10"
		echo "                                  If2<------------->$array11"
		echo "                                  If3<------------->$array12"
		else [[ $input = 'y' ]];
        fi

emu1=$(whereis qemu-kvm | awk '{ print $2}')
emu2=$(whereis qemu-system-x86_64 | awk '{ print $2}')
emu3=$(whereis kvm-spice | awk '{ print $2}')
if [ "${emu1}" != "" ];	then
        emu=$emu1
        elif [ "${emu2}" != "" ]; then
	emu=$emu2
	elif [ "${emu3}" != "" ]; then
	emu=$emu3
	fi

echo "Emulator: "$emu
source_file=$(pwd)
echo "Path: "$source_file
machine=pc
echo "Machine: "$machine
echo " "
echo "Is The Above Information Correct? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
		exit 1
                else [[ $input = 'y' ]];
        fi


echo "<domain type='kvm' id='34'>
  <name>$name</name>
  <memory unit='KiB'>4120576</memory>
  <currentMemory unit='KiB'>4120576</currentMemory>
  <vcpu placement='static'>4</vcpu>
  <os>
    <type arch='x86_64' machine='$machine'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
	<cpu mode='custom' match='exact'>
    <model fallback='allow'>SandyBridge</model>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>$emu</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' io='native'/>
      <source file='$source_file/$1'/>
      <target dev='vda' bus='virtio'/>
	<alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </disk>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <source bridge='$array10'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array11'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array12'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
    </interface>
	<serial type='pty'>
      <source path='/dev/pts/2'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/2'>
      <source path='/dev/pts/2'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </memballoon>
  </devices>
</domain>" > ./$name.xml
rm -rf ./brctl
echo ""
echo "Xml file for the new Virtual Security GW has been generated"

echo "Do you want to add security gateway to KVM? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
		define=$(virsh define $name.xml)
                else [[ $input = 'n' ]];
		echo "You need to define the $name.xml with virsh yourself"
	exit 1
        fi
echo $define
if [ -z "$define" ]; then
	echo " "
	else
	echo "Do you want to start the security gateway? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
                Start=$(virsh start $name)
		echo "Security gatway started"
                else [[ $input = 'n' ]];
                echo " "
		fi	
	fi
	exit 1
###############Open vSwitch config###########################
	else [[ $input = '2' ]];
echo "##################################################################################################"
echo "Clavister Virtual Security Gateway uses three pre-configured virtual interfaces, If1, If2 and If3.
Virtual interfaces must be mapped to Linux bridges or physical adapters.
Please refer to the KVM manual for physical adapters or adapters in SR-IOV mode."
echo "##################################################################################################"
echo " "

Openvswitch=$(lsmod | grep openvswitch | awk '{if(NR<2)print}')
if [ -z "$Openvswitch" ]; then
        echo "No Bridge found Aborting Setup in 5 sec "
        echo "Please download and install openvswitch"
        sleep 5
        exit 1
        else
        echo ""
	fi

echo ""

Vhost_net=$(lsmod | grep vhost_net | awk '{ print $1 }' | awk '{if(NR<2)print}')
if [ -z "$Vhost_net" ]; then
	echo "vhost_net modual not loaded"
	echo "attempting to load modual"
	modprobe vhost_net
	sleep 2
fi
Vhost_net=$(lsmod | grep vhost_net | awk '{ print $1 }' | awk '{if(NR<2)print}')
if [ -z "$Vhost_net" ]; then
	echo "vhost_net modual not loaded"
	echo "Aborting Setup"
	else
	echo "vhost_net modual loaded"
fi
echo ""
echo "The following bridges were found"
ovs-vsctl list-br | awk '{ print $1 }' | awk '{if(NR>0)print}' > openvswitch
filename=./openvswitch
count=$(cat $filename | wc -l)
declare -a array1
array1=( `cat "$filename"`)
nr=0
for i in $(eval echo "{1..$count}")
        do
br_iface=${array1[$nr]}
echo "Bridge interface: " $br_iface
nr=$(($nr + 1))
array10=${array1[0]}
array11=${array1[1]}
array12=${array1[2]}
done
if [ -z "$array11" ] && [ -z "$array12" ]; then
        array11=${array1[0]}
        array12=${array1[0]}
fi
if [ -z "$array12" ]; then
        array12=${array1[1]}
fi

echo ""
echo "This is the default mapping."
echo "Virtual security gateway network interface        Bridge map"
echo "                                  If1<------------->$array10"
echo "                                  If2<------------->$array11"
echo "                                  If3<------------->$array12"
echo " "
echo "Do you want to add them in that order? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
                echo -n "Virtual security gateway If1 bridge: "
                read array10
                echo -n "Virtual security gateway If2 bridge: "
                read array11
                echo -n "Virtual security gateway If3 bridge: "
                read array12
                echo "This mapping was created"
                echo "Virtual security gateway network interface        Bridge map"
                echo "                                  If1<------------->$array10"
                echo "                                  If2<------------->$array11"
                echo "                                  If3<------------->$array12"
                else [[ $input = 'y' ]];
        fi

echo "Emulator: "$emu
source_file=$(pwd)
echo "Path: "$source_file
machine=pc
echo "Machine: "$machine
echo " "
echo "Is The Above Information Correct? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'n' ]]; then
                exit 1
                else [[ $input = 'y' ]];
        fi

echo "<domain type='kvm' id='34'>
  <name>$name</name>
  <memory unit='KiB'>4120576</memory>
  <currentMemory unit='KiB'>4120576</currentMemory>
  <vcpu placement='static'>4</vcpu>
  <os>
    <type arch='x86_64' machine='$machine'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
	<cpu mode='custom' match='exact'>
    <model fallback='allow'>SandyBridge</model>
  </cpu>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>$emu</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none' io='native'/>
      <source file='$source_file/$1'/>
      <target dev='vda' bus='virtio'/>
	<alias name='virtio-disk0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
    </disk>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <interface type='bridge'>
      <source bridge='$array10'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array11'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
    </interface>
    <interface type='bridge'>
      <source bridge='$array12'/>
      <virtualport type='openvswitch'>
      </virtualport>
      <model type='virtio'/>
      <driver name='vhost' txmode='timer' ioeventfd='on' event_idx='off'/>
    </interface>
	<serial type='pty'>
      <source path='/dev/pts/2'/>
      <target port='0'/>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/2'>
      <source path='/dev/pts/2'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'/>
    <video>
      <model type='cirrus' vram='9216' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </memballoon>
  </devices>
</domain>" > ./$name.xml

rm -rf ./openvswitch
echo ""
echo "Xml file for the new Virtual Security GW has been generated"

echo "Do you want to add security gateway to KVM? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
                define=$(virsh define $name.xml)
                else [[ $input = 'n' ]];
                echo "You need to define the $name.xml with virsh yourself"
        exit 1
        fi
echo $define
if [ -z "$define" ]; then
        echo " "
        else
        echo "Do you want to start the security gateway? "
        echo "y) Yes"
        echo "n) No"
                echo -n "Enter Choice: "
                read -e input
                echo
                if [[ $input = 'y' ]]; then
                Start=$(virsh start $name)
                echo "Security gatway started"
                else [[ $input = 'n' ]];
                echo " "
                fi



	fi
fi
esac
done
exit 1
