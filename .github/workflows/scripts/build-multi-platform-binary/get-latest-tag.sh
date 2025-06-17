#!/bin/bash

set -e

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0)

echo "Latest tag: $LATEST_TAG"

# Checkout the latest tag
git checkout "$LATEST_TAG"

# Set output for GitHub Actions
echo "tag_name=$LATEST_TAG" >> $GITHUB_OUTPUT

echo "Checked out tag: $LATEST_TAG"
