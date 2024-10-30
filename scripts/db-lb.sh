#!/usr/bin/sh

# Update package lists
sudo apt-get update

# Upgrade all packages
sudo apt-get upgrade -y

# Install git
sudo apt-get install git -y

# Install HAProxy
sudo apt-get install haproxy -y

# Install wget
sudo apt-get install wget -y

git pull https://github.com/Ligne8/GenArchi-P2.git genarchi

cp genarchi/conf/db-lb-ha/haproxy.cfg /etc/haproxy/haproxy.cfg