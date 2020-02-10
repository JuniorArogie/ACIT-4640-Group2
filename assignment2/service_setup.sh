#!/bin/bash

vbmg () { 
    VBoxManage "$@"; 
    }

NET_NAME="4640"
VM_NAME="VM4640"
PXE_NET="NAT_4640"
PXE_NAME="PXE4640"
SSH_PORT="8022"
WEB_PORT="8000"
VM_RAM=1024
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

vbmg startvm "PXE4640"

while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p 12222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                break
        fi
done

# This function will copy the necessary files to PXE server
scp -P 12222 ks.cfg admin@localhost:/var/www/lighttpd/files
scp -P 12222 ~/.ssh/acit_admin_id_rsa admin@localhost:/var/www/lighttpd/files
scp -P 12222 vm_setup.sh admin@localhost:/var/www/lighttpd/files



# This function will clean the NAT network and the virtual machine
clean_all () {
    vbmg natnetwork remove --netname "$NET_NAME"
    vbmg unregistervm "$VM_NAME" --delete
}

create_network () {
    vbmg natnetwork add --netname "$NET_NAME" --network "192.168.230.0/24" --dhcp off
    vbmg natnetwork modify --netname "$NET_NAME" --network "192.168.230.0/24" --port-forward-4 "rule1:tcp:[127.0.0.1]:12022:[192.168.230.10]:$SSH_PORT"
    vbmg natnetwork modify --netname "$NET_NAME" --network "192.168.230.0/24" --port-forward-4 "rule2:tcp:[127.0.0.1]:12080:[192.168.230.10]:$WEB_PORT"
    
    vbmg natnetwork modify --netname "$PXE_NET" --network "192.168.230.0/24" --port-forward-4 "my_rule2:tcp:[192.168.230.10]:12222:[192.168.230.200]:$SSH_PORT"
    vbmg natnetwork modify --netname "$PXE_NET" --network "192.168.230.0/24" --port-forward-4 "my_rule2:tcp:[192.168.230.10]:12222:[192.168.230.200]:$WEB_PORT"




}

create_vm () {
    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
    vbmg modifyvm "$VM_NAME" --memory 2048 --audio none --vram 16 --cpus 1  \
    --nic1 natnetwork --cableconnected2 on --nat-network1 "$PXE_NET"

    #Connect PXE server to NAT_4640 network
    vbmg modifyvm "$PXE_NAME" --nic1 natnetwork --cableconnected2 on --nat-network1 "$PXE_NET"


    vbmg createmedium disk --size 10000 --filename "$VM_DIR/$VM_NAME".vdi

    vbmg modifyvm "$VM_NAME" --boot1 disk --boot2 net
    
    vbmg storagectl "$VM_NAME" --name "IDE" --add ide 
    vbmg storagectl "$VM_NAME" --name "SATA" --add sata 

    vbmg storageattach "$VM_NAME" --device 0 --port 0 --storagectl IDE --type dvddrive --medium emptydrive

    vbmg storageattach "$VM_NAME" --device 0 --port 1 --storagectl SATA --type hdd --medium "$VM_DIR/$VM_NAME".vdi
}

echo "Starting script..."

clean_all
create_network
create_vm

#Starts the TODO VM
vbmg startvm "$VM_NAME"


echo "DONE!"

