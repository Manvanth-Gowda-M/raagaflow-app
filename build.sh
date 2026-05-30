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

echo "=== Checking API Keys ==="
API_KEYS_FILE="lib/core/constants/api_keys.dart"
if [ ! -f "$API_KEYS_FILE" ]; then
  echo "API Keys file not found. Generating dummy/placeholder api_keys.dart..."
  mkdir -p lib/core/constants
  
  # Check if env variables are present, otherwise use placeholder values
  JAMENDO_ID=${JAMENDO_CLIENT_ID:-"YOUR_JAMENDO_CLIENT_ID"}
  PIXABAY_KEY=${PIXABAY_API_KEY:-"YOUR_PIXABAY_API_KEY"}
  
  cat <<EOF > "$API_KEYS_FILE"
// Generated automatically during Vercel build
class ApiKeys {
  static const String jamendoClientId = '$JAMENDO_ID';
  static const String pixabayApiKey = '$PIXABAY_KEY';
}
EOF
  echo "Generated: $API_KEYS_FILE"
else
  echo "API Keys file already exists locally in build."
fi

echo "=== Configuring Flutter Web ==="
flutter config --enable-web

echo "=== Building Flutter Web Application (Release) ==="
flutter build web --release --no-tree-shake-icons

echo "=== Build Completed Successfully! ==="
