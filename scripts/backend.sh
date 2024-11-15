#!/bin/sh

{

echo "Waiting for internet connection..."
  while ! ping -c 1 -W 1 google.com; do
    sleep 1
  done
  echo "Internet connection established."

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

apt-get install -y postgresql postgresql-contrib

cd app/backend

npm install
npm install -g typescript ts-node
 
while ! pg_isready -h 10.0.3.10 -p 5432; do   
  sleep 1
done

npx prisma db push
npx ts-node index.ts
} >> /tmp/backend.log 2>&1
