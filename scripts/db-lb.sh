#!/usr/bin/sh

# Update package lists
sudo apt-get update

# Upgrade all packages
sudo apt-get upgrade -y

# Install git
sudo apt-get install git -y

# Install HAProxy
sudo apt-get install haproxy -y
