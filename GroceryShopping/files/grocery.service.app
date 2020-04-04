[Unit]
Description=Grocery app, Final Project
After=network.target

[Service]
Environment=NODE_PORT=3001
WorkingDirectory=/home/admin/Node-Express-MySQL-GroceryShopping
Type=simple
User=admin
ExecStart=/usr/bin/node /home/admin/Node-Express-MySQL-GroceryShopping/app.js
Restart=always

[Install]
WantedBy=multi-user.target