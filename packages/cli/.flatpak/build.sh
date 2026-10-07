#!/bin/bash
set -e

# Configuration
APP_NAME="com.dart_nostr.ndk"
BUILD_DIR="/tmp/${APP_NAME}.build"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLATPAK_MANIFEST="${SOURCE_DIR}/${APP_NAME}.flatpak"
VERSION=$(grep -oP 'version: \K[0-9.]+' "${SOURCE_DIR}/pubspec.yaml" | head -1)

echo "=== Building Flatpak Package for NDK CLI ==="
echo "Source directory: ${SOURCE_DIR}"
echo "Version: ${VERSION:-unspecified}"

# Create build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Set up local repository if exists
if [ -d "${SOURCE_DIR}/.flatpak/repo" ]; then
    echo "Setting up local Flatpak repository..."
    flatpakrepo --if-not-exists file://${SOURCE_DIR}/.flatpak/repo \
        --noninteractive \
        --unprivileged \
        --gpg-verify=false

    # Download and set up SDK
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.json
fi

# Build the Dart executable first
echo "=== Building Dart CLI executable ==="
cd "${SOURCE_DIR}"



# Install dependencies if needed
dart pub get

# Build the CLI executable for Linux
echo "Building NDK CLI..."
dart build cli --target=./../bin/ndk.dart

# Move the built executable to a temporary location for Flatpak
BUILD_OUTPUT="./../build/cli/linux_x64/bundle/bin/ndk"
if [ -f "${BUILD_OUTPUT}" ]; then
    echo "Found built executable at: ${BUILD_OUTPUT}"
    cp "${BUILD_OUTPUT}" "${SOURCE_DIR}/${APP_NAME}.flatpak"
else
    echo "ERROR: Could not find built executable at ${BUILD_OUTPUT}"
    echo "Run 'dart build cli exe --linux' first"
    exit 1
fi

# Copy the manifest
cp "${SOURCE_DIR}/${APP_NAME}.flatpak" "${BUILD_DIR}/"

echo "=== Building Flatpak ==="
# Build with flatpak-builder
flatpak run --command=flathub-build org.flatpak.Builder --install ./com.dart_nostr.ndk.yml


echo "=== Build Complete ==="
echo ""
echo "To run the app:"
echo "  flatpak run ${APP_NAME}"
