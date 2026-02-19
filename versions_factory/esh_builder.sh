#!/bin/bash
echo "------------------------------------------"
echo "   ESH VERSIONS FACTORY - Main Control    "
echo "------------------------------------------"
echo "Available Versions to Build:"
ls build_v*.sh | sed 's/build_//' | sed 's/.sh//'
echo "------------------------------------------"
read -p "Enter version name to build (e.g., v3.0): " ver
if [ -f "build_$ver.sh" ]; then
    echo "🚀 Building ESH $ver..."
    bash "build_$ver.sh"
else
    echo "❌ Version not found!"
fi
