#!/bin/sh

{
apt-get update
apt upgrade -y

# Install git
apt-get install git -y

# Clone the repository
git clone https://github.com/Ligne8/GenArchi-P2.git app

# Install npm
apt-get install npm -y

# Install nodejs
apt-get install nodejs -y

cd app/backend

npm install
npm install -g typescript ts-node

sleep 240

npx prisma db push
npx ts-node index.ts
} >> /tmp/backend.log 2>&1
