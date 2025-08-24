#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Function to check if Docker command is functional
is_docker_functional() {
    docker info > /dev/null 2>&1
}

# Check if Docker is installed and functional
if ! [ -x "$(command -v docker)" ] || ! is_docker_functional; then
    echo "Docker is not installed or not functional. Installing Docker..."

    # Update the apt package index
    sudo apt-get update

    # Install packages to allow apt to use a repository over HTTPS
    sudo apt-get install -y ca-certificates curl gnupg 

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo rm -f /etc/apt/keyrings/docker.gpg  # Remove existing key if it exists
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the apt package index again
    sudo apt-get update

    # Install the latest version of Docker Engine and containerd
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Verify that Docker Engine is installed correctly by running the hello-world image
    sudo docker run hello-world
else
    echo "Docker is already installed and functional."
fi

# Function to add a user to the docker group
add_user_to_docker_group() {
    local user=$1
    echo "Adding user $user to the docker group..."
    sudo usermod -aG docker $user
}

# Get all WSL users (excluding system users)
users=$(getent passwd {1000..60000} | cut -d: -f1)

for user in $users; do
    add_user_to_docker_group $user
done

# Restart Docker service
echo "Restarting Docker service..."
sudo systemctl restart docker

echo "All WSL users have been added to the Docker group."