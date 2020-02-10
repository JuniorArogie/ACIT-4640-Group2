#!/bin/bash

# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="test4640"
VM_NAME="TODO4640_Module4"
SSH_PORT="12022"
WEB_PORT="12080"
PXE_NAME="PXE4640"



# This function will clean the NAT network and the VM
clean_all () {
    vbmg natnetwork remove --netname $NET_NAME
    vbmg unregistervm "$VM_NAME" --delete
    echo "######################################### deleted network and VM##################################"

}

#Create the Network
create_network(){
    vbmg natnetwork add --netname $NET_NAME --network "192.168.230.0/24" --enable --dhcp enable --ipv6 off

    vbmg natnetwork modify \
        --netname $NET_NAME --port-forward-4 "ssh:tcp:[]:12022:[192.168.230.10]:22" \
        --port-forward-4 "http:tcp:[]:12080:[192.168.230.10]:80" \
        --port-forward-4 "ssh2:tcp:[]:12222:[192.168.230.200]:22"
        
    vbmg modifyvm $PXE_NAME \
		--nic1 natnetwork \
		--nat-network1 "$NET_NAME"
        
    
    echo "###################################### Created Network #########################################"
}

# Creates a new VM
create_vm () {

    vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register

    vbmg modifyvm "$VM_NAME"\
										--cpus 1\
										--memory 2048 \
										--vram 16 --audio none \
										--nic1 natnetwork\
										--nat-network1 "$NET_NAME"\
										--boot1 disk\
										--boot2 net\
										--boot3 none\
										--boot4 none\

    SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
    VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
    VM_DIR=$(dirname "$VBOX_FILE")
    DISK_NAME="$VM_DIR/$VM_NAME"

    vbmg createmedium disk --filename "$DISK_NAME" --size 20480
    
    vbmg storagectl "$VM_NAME" --name "SATA Controller" --add sata
    vbmg storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 \
    --device 0 --type hdd --medium "$DISK_NAME".vdi
    vbmg storagectl "$VM_NAME" --name "IDE Controller" --add ide
    
    echo "############################################ Created VM #########################################"
}

#Start the PXE VM auto
start_PXE(){
    chmod 600 ./setup/authorized_keys
    vbmg startvm $PXE_NAME
    while /bin/true; do
#    ssh pxe exit
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
echo "############################################ PXE STARTED #################################"
}

# move the file into the PXE: move all the file in to pxe then move to specific file
move_PXE_file(){
	scp -r ./setup pxe:~
    ssh pxe "sudo mv ~/setup/authorized_keys /var/www/lighttpd/files"
    ssh pxe "sudo mv ~/setup/ks.cfg /var/www/lighttpd/files"
       
echo"############################################Movefinished##################################"
}


#starting the VM and setup the VM
start_vm(){
    vbmg startvm "$VM_NAME"
    while /bin/true; do
#    ssh pxe exit
    ssh -i ~/.ssh/acit_admin_id_rsa -p 12022 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "TODO APP server is not up, sleeping..."
                sleep 2
        else
                vbmg controlvm $PXE_NAME poweroff
                break
                
        fi
        done
        
echo "############################################ TODOAPP STARTED #################################"
}

#run the vm_setup.sh in WSL
bash_vm(){
   cd ~/windows/Desktop/assignment2/setup && bash vm_setup.sh
}

clean_all

create_network

create_vm

start_PXE

move_PXE_file

start_vm

bash_vm
