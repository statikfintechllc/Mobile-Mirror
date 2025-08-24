#!/bin/bash

# Function to check if a user is in the docker group
check_user_in_docker_group() {
    local user=$1
    if ! groups $user | grep -q "\bdocker\b"; then
        echo "User $user is NOT in the docker group. Exiting with error."
        exit 1
    else
        echo "User $user is in the docker group."
    fi
}

# Get all WSL users (excluding system users)
users=$(getent passwd {1000..60000} | cut -d: -f1)

# Check each user
for user in $users; do
    check_user_in_docker_group $user
done

echo "All users are in the Docker group."
echo "Validation complete."
