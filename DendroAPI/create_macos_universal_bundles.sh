#!/bin/bash

# Script to create universal macOS bundle from Intel and ARM builds
# Usage: ./create-universal-bundle.sh <intel_bundle_path> <arm_bundle_path> <output_bundle_path>

set -e  # Exit on any error

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <intel_bundle_path> <arm_bundle_path> <output_bundle_path>"
    echo "Example: $0 build-intel/DendroAPI_macos.bundle build-arm/DendroAPI_macos.bundle DendroAPI_macos_universal.bundle"
    exit 1
fi

INTEL_BUNDLE="$1"
ARM_BUNDLE="$2"
OUTPUT_BUNDLE="$3"

# Define paths to the binaries inside bundles
INTEL_BINARY="$INTEL_BUNDLE/Contents/MacOS/DendroAPI_macos"
ARM_BINARY="$ARM_BUNDLE/Contents/MacOS/DendroAPI_macos"

echo "=== Creating Universal macOS Bundle ==="
echo "Intel bundle: $INTEL_BUNDLE"
echo "ARM bundle: $ARM_BUNDLE"
echo "Output bundle: $OUTPUT_BUNDLE"
echo

# Verify the bundles exist
echo "Checking for Intel bundle..."
if [ ! -d "$INTEL_BUNDLE" ]; then
    echo "Error: Intel bundle not found at $INTEL_BUNDLE"
    exit 1
fi

echo "Checking for ARM bundle..."
if [ ! -d "$ARM_BUNDLE" ]; then
    echo "Error: ARM bundle not found at $ARM_BUNDLE"
    exit 1
fi

# Verify the binaries exist
echo "Checking for Intel binary..."
if [ ! -f "$INTEL_BINARY" ]; then
    echo "Error: Intel binary not found at $INTEL_BINARY"
    echo "Bundle contents:"
    find "$INTEL_BUNDLE" -type f
    exit 1
fi

echo "Checking for ARM binary..."
if [ ! -f "$ARM_BINARY" ]; then
    echo "Error: ARM binary not found at $ARM_BINARY"
    echo "Bundle contents:"
    find "$ARM_BUNDLE" -type f
    exit 1
fi


# Show architecture info for both binaries
echo
echo "=== Binary Architecture Info ==="
echo "Intel binary architecture:"
file "$INTEL_BINARY"

echo "ARM binary architecture:"
file "$ARM_BINARY"

# Copy Intel bundle as the base for universal bundle
echo
echo "=== Creating Universal Bundle ==="
echo "Creating universal bundle from Intel bundle..."
cp -R "$INTEL_BUNDLE" "$OUTPUT_BUNDLE"

# Create universal binary using lipo
echo "Creating universal binary with lipo..."
TEMP_UNIVERSAL_BINARY="$(mktemp)"
lipo -create \
    "$INTEL_BINARY" \
    "$ARM_BINARY" \
    -output "$TEMP_UNIVERSAL_BINARY"

# Verify the universal binary
echo "Universal binary architecture info:"
lipo -info "$TEMP_UNIVERSAL_BINARY"
file "$TEMP_UNIVERSAL_BINARY"

# Replace the binary in the universal bundle
echo "Replacing binary in universal bundle..."
cp "$TEMP_UNIVERSAL_BINARY" "$OUTPUT_BUNDLE/Contents/MacOS/DendroAPI_macos"

# Clean up temp file
rm "$TEMP_UNIVERSAL_BINARY"

# Verify the final bundle binary
echo
echo "=== Final Verification ==="
echo "Final bundle binary architecture:"
lipo -info "$OUTPUT_BUNDLE/Contents/MacOS/DendroAPI_macos"

echo
echo "Universal bundle created successfully!"
echo "Bundle contents:"
find "$OUTPUT_BUNDLE" -type f

echo
echo "Bundle size: $(du -sh "$OUTPUT_BUNDLE" | cut -f1)"
echo "Binary architecture: $(lipo -info "$OUTPUT_BUNDLE/Contents/MacOS/DendroAPI_macos")"