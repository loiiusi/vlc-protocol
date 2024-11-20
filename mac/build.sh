#!/bin/bash -e

# script path
script_path=$(realpath $0)
# change to script directory
cd $(dirname "$script_path")

# Parse command line arguments
generate_plist=false
install_app=false
install_path=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --plist)
      generate_plist=true
      shift
      ;;
    --install)
      install_app=true
      shift
      ;;
    --install-to)
      if [[ -z "$2" ]]; then
        echo "Error: --install-to requires a directory path"
        exit 1
      fi
      install_path="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      echo "Usage: $0 [--plist] [--install] [--install-to <path>]"
      exit 1
      ;;
  esac
done

# Create app structure
mkdir -p VLC-protocol-app/Contents/{MacOS,Resources}

# Compile the application
gcc -mmacosx-version-min=10.4 -arch x86_64 -arch arm64 -framework Cocoa -o VLC-protocol-app/Contents/MacOS/vlc-protocol vlc-protocol.m

# Generate Info.plist if requested
if [ "$generate_plist" = true ]; then
  cat > VLC-protocol-app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>vlc-protocol</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.vlc-protocol</string>
    <key>CFBundleName</key>
    <string>VLC Protocol Handler</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.4</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>VLC Protocol</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>vlc</string>
            </array>
        </dict>
    </array>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
fi

echo "Application built successfully at: VLC-protocol-app"

# Handle installation
if [ -n "$install_path" ]; then
  # --install-to was specified
  install_dir="$install_path"
  echo "Installing to specified path: $install_dir"
  rm -rf "$install_dir/VLC-protocol.app"
  mkdir -p "$install_dir"
  cp -r VLC-protocol-app "$install_dir/VLC-protocol.app"
  echo "Application installed to: $install_dir/VLC-protocol.app"
elif [ "$install_app" = true ]; then
  # --install was specified
  install_dir="$HOME/Applications"
  echo "Installing to user Applications folder: $install_dir"
  rm -rf "$install_dir/VLC-protocol.app"
  mkdir -p "$install_dir"
  cp -r VLC-protocol-app "$install_dir/VLC-protocol.app"
  echo "Application installed to: $install_dir/VLC-protocol.app"
else
  echo "To install, use --install or --install-to <path>"
fi