#!/bin/bash

echo "=== System Diagnostic ==="
uname -a
node --version

echo "=== Downloading Flutter SDK (Stable) ==="
# Clone the Flutter SDK dynamically into the build environment
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to the path of the current execution shell
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Verifying Flutter installation ==="
flutter --version

echo "=== Configuring Flutter Web ==="
flutter config --enable-web

echo "=== Building Flutter Web Application (Release) ==="
flutter build web --release --no-tree-shake-icons

echo "=== Build Completed Successfully! ==="
