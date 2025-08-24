#!/bin/bash

# Set the script to exit immediately on any command error
# set -e

export DEBIAN_FRONTEND=noninteractive

###################################
# Prerequisites
CONDA_DIR="/opt/miniconda"

# Get the directory of the current script
SCRIPT_DIR="$(dirname "$0")"

# Update the list of packages
echo "Updating package list..."
sudo apt-get update

# Install pre-requisite packages.
echo "Installing prerequisite packages..."
sudo apt-get install -y wget apt-transport-https ca-certificates curl software-properties-common


###################################
# Install Conda

# Check if Conda is not already installed
if [ ! -f "$CONDA_DIR/bin/conda" ]; then
    echo "Downloading Miniconda installer..."
    CONDA_INSTALLER=Miniconda3-latest-Linux-x86_64.sh 
    CONDA_INSTALLER_LOCAL_PATH="/var/tmp/$CONDA_INSTALLER"
    wget https://repo.anaconda.com/miniconda/$CONDA_INSTALLER -O $CONDA_INSTALLER_LOCAL_PATH 2>&1 

    echo "Installing Miniconda..."
    bash $CONDA_INSTALLER_LOCAL_PATH -b -p $CONDA_DIR 2>&1

    echo "Removing installer..."
    rm $CONDA_INSTALLER_LOCAL_PATH

    # Set permissions for all users
    echo "Setting full permissions for all users on $CONDA_DIR"
    chmod -R 777 $CONDA_DIR

    # Initialize Conda for bash shell
    echo "Initializing Conda for bash..."
    $CONDA_DIR/bin/conda init
    
    # Optionally, add Conda to PATH (depends on your preferences)
    echo "Adding Conda to PATH in ~/.bashrc..."
    . ~/.bashrc
else
    echo "Conda is already installed. Skipping installation."
fi

# refresh PATH to use Conda
. ~/.bashrc

echo "Script execution completed."
