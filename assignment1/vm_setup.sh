#!/bin/bash
#PART 1: Git/Node/Mongo

USER_NAME="todoapp"

install_services () {
    sudo yum get update
    sudo yum install git
    sudo yum install npm
    sudo yum install mongodb-server
    sudo systemctl enable mongod && systemctl start mongod
}
install_services

create_user(){
    sudo useradd "$USER_NAME"
    sudo passwd "$USER_NAME"
    todoapp - Password
    su - "$USER_NAME"
    cd
}
create_user


git clone https://github.com/timoguic/ACIT4640-todo-app


npm install

cd ACIT4640-todo-app/

cd config

echo "module.exports = {localURl: 'mongodb://localhost/acit4640'};" >> database.js

cd ..

#Turn off the firewall
#firewall-cmd --zone=public --add-port=8080/tcp
#firewall-cmd --zone=public --add-port=80/tcp

sudo systemctl stop firewalld

node server.js


#PART 1 DONE
#PART 2 NGINX

sudo yum install nginx
sudo systemctl enable nginx
sudo systemctl start nginx

cd /etc/nginx/
sudo cp nginx.conf /etc/nginx/

sudo systemctl restart nginx

cd app/ACIT4640-todo-app/
node server.js

#PART 2 DONE
#PART 3

cd /etc/systemd/system

sudo echo "[Unit]
Description=Todo app, ACIT4640
After=network.target" >> todoapp.service

sudo echo "[Service]
Environment=NODE_PORT=8080
WorkingDirectory=/home/todoapp/app
Type=simple
User=todoapp
ExecStart=/usr/bin/node /home/todoapp/app/server.js
Restart=always
" >> todoapp.service

sudo echo "[Install]
WantedBy=multi-user.target" >> todoapp.service

sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl start todoapp
sudo systemctl stop firewalld

sudo systemctl status

