# Prepare_cOS
Helper script for Clavister firewall on KVM

This script is intended to help setup cOS Core and cOS Stream in a KVM enviroment.
It has support for brutils and open vswitch, I recommend OpenVSwitch.

How to use.
Download the Clavister cOS Core 11.01.00 for KVM to your KVM host
Unzip the file and move it to where you want.
Download the https://github.com/Clavister/Prepare_cOS/archive/master.zip and unzip it
Move the prepare.sh to the same directory where you have clavister kvm img file.
Make the script executable with chmod +x prepare.sh
Run the script with the img as argument ex. ./prepare.sh cOS-Core-11.01.00-KVM.img
The script will ask a couple of questions. 
