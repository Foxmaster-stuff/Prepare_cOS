# Prepare_cOS
Helper script for Clavister firewall on KVM

This script is intended to help setup cOS Core and cOS Stream in a KVM enviroment.
It has support for brutils and open vswitch, I recommend OpenVSwitch.

### How to use.
1. Download the Clavister cOS Core 11.01.00 for KVM to your KVM host
2. Unzip the file and move it to where you want.
3. Download the https://github.com/Clavister/Prepare_cOS/archive/master.zip and unzip it
4. Move the prepare.sh to the same directory where you have clavister kvm img file.
5. Make the script executable with chmod +x prepare.sh
6. Run the script with the img as argument ex. ./prepare.sh cOS-Core-11.01.00-KVM.img
7. The script will ask a couple of questions. 
