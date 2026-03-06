#!/bin/bash
set -e

cd flutter_app

echo "Backing up important iOS files..."
mkdir -p /tmp/ios_backup
cp -r ios/Runner /tmp/ios_backup/ || true

echo "Deleting iOS folder..."
rm -rf ios

echo "Recreating iOS folder..."
flutter create --platforms=ios .

echo "Restoring Runner customizations..."
cp -r /tmp/ios_backup/Runner/* ios/Runner/

echo "Installing pods..."
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..

echo "iOS recreated successfully!"
