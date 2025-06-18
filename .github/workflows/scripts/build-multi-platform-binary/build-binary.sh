#!/bin/bash

set -e

# Extract version from tag (remove 'v' prefix if present)
VERSION=${TAG_NAME#v}
BINARY_NAME="BinaryDependenciesManager"
PLATFORM=${PLATFORM:-macOS}
ARCH=${ARCH:-universal}
ARCHIVE_NAME="BinaryDependenciesManager-${PLATFORM}-${ARCH}-${VERSION}.zip"

echo "Building binary for platform: $PLATFORM, architecture: $ARCH, version: $VERSION"

# Create build directory
mkdir -p build

if [ "$PLATFORM" == "macOS" ] && [ "$ARCH" == "universal" ]; then
    # Build universal binary for macOS
    echo "Building universal binary for macOS..."
    swift build --configuration release --arch x86_64 --arch arm64
    cp .build/apple/Products/Release/$BINARY_NAME build/$BINARY_NAME

    # Verify the universal binary
    echo "Verifying universal binary..."
    lipo -info build/$BINARY_NAME
elif [ "$PLATFORM" == "macOS" ] && [[ "$ARCH" == "arm64" || "$ARCH" == "x86_64" ]]; then

    # Build $ARCH binary for macOS
    echo "Building $ARCH binary for macOS..."
    swift build --configuration release --arch $ARCH
    cp .build/$ARCH-apple-macosx/release/$BINARY_NAME build/$BINARY_NAME

    # Verify the binary
    echo "Verifying binary..."
    file build/$BINARY_NAME
elif [ "$PLATFORM" == "linux" ] && [ "$ARCH" == "x86_64" ]; then
    # Build for Linux x86_64
    echo "Building for Linux x86_64..."
    swift build --configuration release
    cp .build/release/$BINARY_NAME build/$BINARY_NAME

    # Verify the binary
    echo "Verifying binary..."
    file build/$BINARY_NAME
else
    echo "Unsupported platform/architecture combination: $PLATFORM/$ARCH"
    exit 1
fi

# Create the archive
echo "Creating archive: $ARCHIVE_NAME"
cd build

if [ "$PLATFORM" == "macOS" ]; then
    # Use ditto on macOS
    ditto -c -k --sequesterRsrc --keepParent $BINARY_NAME "../$ARCHIVE_NAME"
elif [ "$PLATFORM" == "linux" ]; then
    # Use zip on Linux
    zip "../$ARCHIVE_NAME" $BINARY_NAME
else
    echo "Unsupported platform for archiving: $PLATFORM"
    exit 1
fi

cd ..

# Verify the archive was created
if [ -f "$ARCHIVE_NAME" ]; then
    echo "Archive created successfully: $ARCHIVE_NAME"
    echo "Archive size: $(du -h $ARCHIVE_NAME | cut -f1)"

    # Set outputs for GitHub Actions
    echo "asset_path=$PWD/$ARCHIVE_NAME" >> $GITHUB_OUTPUT
    echo "asset_name=$ARCHIVE_NAME" >> $GITHUB_OUTPUT
else
    echo "Error: Archive was not created"
    exit 1
fi

# Clean up build artifacts
rm -rf build
