#!/bin/sh
# security find-identity

cd .builtapp

git clone https://github.com/dripcap/dripcap-helper.git
cp ./dripcap-darwin/dripcap.app/Contents/Resources/app/node_modules/paperfilter/bin/paperfilter dripcap-helper/paperfilter
cd dripcap-helper
xcodebuild -configuration Release
cd ..

cp -r ./dripcap-helper/build/Release/Dripcap\ Helper\ Installer.app ./dripcap-darwin/dripcap.app/Contents/Frameworks
codesign --deep --force --verify --verbose --sign "$DRIPCAP_DARWIN_SIGN" ./dripcap-darwin/dripcap.app/Contents/Frameworks/*
codesign --deep --force --verify --verbose --sign "$DRIPCAP_DARWIN_SIGN" "./dripcap-darwin/dripcap.app"
ditto -c -k --sequesterRsrc --keepParent ./dripcap-darwin/dripcap.app ../dripcap-darwin.zip
