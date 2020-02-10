#!/bin/bash
USER_NAME="todoapp"
#use to install the service that we neeed
install_services(){
    ssh todoapp 'sudo yum upgrade -y'
    ssh todoapp 'sudo yum install git -y'
    ssh todoapp 'sudo yum install nodejs -y'
    ssh todoapp 'sudo yum install mongodb-server -y'
    ssh todoapp 'sudo systemctl enable mongod && sudo systemctl start mongod'
    ssh todoapp 'sudo yum install nginx -y'
    
    echo "############################################ finished install############################################ "
}

#use to create the todo user and set the password and change the permission
create_user(){
    ssh todoapp "sudo useradd "$USER_NAME""
    ssh todoapp 'echo todoapp:P@ssw0rd | sudo chpasswd'
	ssh todoapp 'sudo chown -R todoapp /home/todoapp'
    ssh todoapp 'sudo chmod 755 -R /home/todoapp'
    echo "############################################ User created and permission changed ############################################ "
}

#use to download from Tim's github
get_app(){
    ssh todoapp 'sudo mkdir /home/todoapp/app'
    ssh todoapp 'sudo git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todoapp/app/ACIT4640-todo-app'
	echo "############################################ APP Cloned############################################ "
}

#use to move the files to correct places
move_configs(){
    scp -r ./database.js todoapp:~
    scp -r ./todoapp.service todoapp:~
    scp -r ./nginx.conf todoapp:~
	ssh todoapp "sudo rm /home/todoapp/app/ACIT4640-todo-app/config/database.js"
    ssh todoapp "sudo rm /etc/nginx/nginx.conf"
    ssh todoapp "sudo cp ~/database.js /home/todoapp/app/ACIT4640-todo-app/config/"
    ssh todoapp "sudo cp ~/nginx.conf /etc/nginx/"
    ssh todoapp "sudo cp ~/todoapp.service /etc/systemd/system"
	
	echo "############################################ move configs done############################################ "
}

#use to restart service
service_start(){
    ssh todoapp 'sudo systemctl daemon-reload'
    ssh todoapp 'sudo systemctl enable nginx'
    ssh todoapp 'sudo systemctl start nginx'
    ssh todoapp 'sudo systemctl enable todoapp'
    ssh todoapp 'sudo systemctl start todoapp'
echo "############################################ service started############################################ "
}

#npm install
connect(){
    ssh todoapp "cd /home/todoapp/app/ACIT4640-todo-app"
    ssh todoapp "cd /home/todoapp/app/ACIT4640-todo-app && sudo npm install"
#	ssh todoapp "cd /home/todoapp/app/ACIT4640-todo-app && sudo node server.js"

    echo "############################################finished############################################"
}
install_services

create_user

get_app

move_configs

connect

service_start

