#!/bin/bash

# This is a shortcut function that makes it shorter and more readable
vbmg () { 
    VBoxManage "$@"; 
    }

NET_NAME="4640"
VM_NAME="VM4640"
SSH_PORT="8022"
WEB_PORT="8000"
VM_RAM = 1024
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

# This function will clean the NAT network and the virtual machine
clean_all () {
    vbmg natnetwork remove --netname "$NET_NAME"
    vbmg unregistervm "$VM_NAME" --delete
}

create_network () {
    vbmg natnetwork add --netname "$NET_NAME" --network "192.168.230.0/24" --dhcp off
    vbmg natnetwork modify --netname "$NET_NAME" --network "192.168.230.0/24" --port-forward-4 "my_rule1:tcp:[127.0.0.1]:12022:[192.168.230.10]:$SSH_PORT"
    vbmg natnetwork modify --netname "$NET_NAME" --network "192.168.230.0/24" --port-forward-4 "my_rule2:tcp:[127.0.0.1]:12080:[192.168.230.10]:$WEB_PORT"


}

create_vm () {
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME" --memory 1024 --audio none --vram 16 --cpus 1  \
    --nic2 natnetwork --cableconnected2 on --nat-network2 "$NET_NAME"

    vbmg createmedium disk --filename "$VM_FILE" --size $VM_SIZE
    
    vbmg storagectl "$VM_NAME" --name "IDE" --add ide 
    vbmg storagectl "$VM_NAME" --name "SATA" --add sata 

    vbmg storageattach "$VM_NAME" --device 0 --port 0 --storagectl IDE --type dvddrive --medium emptydrive

    vbmg storageattach "$VM_NAME" --device 0 --port 1 --storagectl SATA --type hdd --medium "$VM_DIR/$VM_NAME".vdi
}

echo "Starting script..."

clean_all
create_network
create_vm

echo "DONE!"