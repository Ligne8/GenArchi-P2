#!/bin/sh

apt-get update
apt upgrade -y

#Install git
apt-get install git -y

#Clone the repository
git clone https://github.com/Ligne8/GenArchi-P2.git app

#Install npm
apt-get install npm -y

#Install nodejs
apt-get install nodejs -y

cd app/app

npm install

sed -i '' "s|const API_GATEWAY_URL = \".*\"|const API_GATEWAY_URL = \"$BACKEND_URL\"|g" index.html

npm start