#!/bin/bash

# Check if Docker is installed
if [ -x "$(command -v docker)" ]; then
    echo "Docker is installed. Uninstalling Docker..."

    # Uninstall Docker Engine, CLI, containerd, and plugins
    sudo apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Remove Docker's GPG key and sources list
    sudo rm -f /etc/apt/keyrings/docker.gpg
    sudo rm -f /etc/apt/sources.list.d/docker.list

    # Remove the keyrings directory if empty
    sudo rmdir /etc/apt/keyrings

    # Update the apt package index
    sudo apt-get update

    echo "Docker has been uninstalled."
else
    echo "Docker is not installed."
fi
