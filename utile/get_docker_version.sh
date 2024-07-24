#!/bin/bash

# Docker Hub repository details
REPO="$1"

# Function to fetch tags from Docker Hub API
fetch_tags() {
    curl -s "https://hub.docker.com/v2/repositories/$REPO/tags/?page_size=100" | jq -r '.results[].name'
}

# Function to handle pagination (if there are more than 100 tags)
fetch_all_tags() {
    URL="https://hub.docker.com/v2/repositories/$REPO/tags/?page_size=100"
    while [ -n "$URL" ]; do
        RESPONSE=$(curl -s "$URL")
        echo "$RESPONSE" | jq -r '.results[].name'
        URL=$(echo "$RESPONSE" | jq -r '.next')
    done
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to continue."
    exit 1
fi

# Fetch and print all tags
echo "Fetching bind9 Docker image tags..."
fetch_all_tags
