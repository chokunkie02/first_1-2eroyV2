#!/bin/bash

# Define output filename
OUTPUT_FILE="mobile_project_source.tar.gz"

# Create tarball, excluding Linux-specific and build folders
echo "Compressing project for mobile..."
tar -czvf $OUTPUT_FILE . \
    --exclude="linux" \
    --exclude="windows" \
    --exclude="macos" \
    --exclude="build" \
    --exclude=".dart_tool" \
    --exclude=".git" \
    --exclude=".idea" \
    --exclude="assets/libs" \
    --exclude="package_for_mobile.sh" \
    --exclude="$OUTPUT_FILE"

echo "Done! created $OUTPUT_FILE"
echo "You can send this file to your mobile phone or developer."
