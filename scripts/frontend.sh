#!/bin/sh

{

apt-get update
apt upgrade -y

#Install git
apt-get install git -y

mkdir /app
#Clone the repository
git clone https://github.com/Ligne8/GenArchi-P2.git /app

#Install npm
apt-get install npm -y

#Install nodejs
apt-get install nodejs -y

cd /app/app

npm install

echo "######################################"
echo ${BACKEND_URL}
echo ${test}
echo "######################################"

sed -i "s|const API_GATEWAY_URL = \".*\"|const API_GATEWAY_URL = \"http://${BACKEND_URL}:8080\"|g" /app/app/src/Portfolio.js

npm start

} >> /tmp/frontend.log 2>&1
