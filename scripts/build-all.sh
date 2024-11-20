#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
DIST_DIR="$PROJECT_ROOT/dist"

# Create dist directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo -e "\nBuilding all packages..."

# Build Windows exe version
echo -e "\nBuilding Windows exe version..."
cd "$PROJECT_ROOT/windows/exe"
./build.sh
zip -r "$DIST_DIR/vlc-protocol-windows-exe.zip" \
  vlc-protocol.exe \
  vlc-protocol-register.bat \
  vlc-protocol-deregister.bat

# Build macOS version
echo -e "\nBuilding macOS version..."
cd "$PROJECT_ROOT/mac"
./build.sh
cp -r "$PROJECT_ROOT/mac/VLC-protocol-app" "$DIST_DIR/VLC-protocol.app"
cd "$DIST_DIR"
zip -r "vlc-protocol-macos-universal.zip" "VLC-protocol.app"
rm -rf "VLC-protocol.app"


# Package Windows PowerShell version
echo -e "\nPackaging Windows PowerShell version..."
cd "$PROJECT_ROOT/windows/ps"
zip -r "$DIST_DIR/vlc-protocol-windows-powershell.zip" \
    vlc-protocol.ps1 \
    vlc-protocol-register.ps1 \
    vlc-protocol-deregister.ps1

# Package Windows batch version
echo -e "\nPackaging Windows batch version..."
cd "$PROJECT_ROOT/windows/bat"
zip -r "$DIST_DIR/vlc-protocol-windows-bat.zip" \
    vlc-protocol.bat \
    vlc-protocol-register.bat \
    vlc-protocol-deregister.bat

# Package Linux version
echo -e "\nPackaging Linux version..."
cd "$PROJECT_ROOT/linux"
chmod +x vlc-protocol
zip -r "$DIST_DIR/vlc-protocol-linux.zip" \
    vlc-protocol \
    vlc-protocol.desktop \
    README.md

echo -e "\nBuild complete! Packages are in the dist directory:"
ls -lh "$DIST_DIR"