# security find-identity

wget -q $MAC_CERT_URL
echo $MAC_CERT_KEY | gpg -d --batch --passphrase-fd 0 -o certificate.zip certificate.zip.gpg
unzip certificate.zip

security create-keychain -p travis osx-build.keychain
security default-keychain -s osx-build.keychain
security unlock-keychain -p travis osx-build.keychain
security set-keychain-settings -t 3600 -l ~/Library/Keychains/osx-build.keychain

security import dev.cer -k ~/Library/Keychains/osx-build.keychain -T /usr/bin/codesign
security import dev.p12 -k ~/Library/Keychains/osx-build.keychain -P "" -T /usr/bin/codesign

export DRIPCAP_DARWIN_SIGN=C0AC25D3DB05BDAF758A4E0A002F25F63F2FC93A

gulp darwin-sign
cd .builtapp

git clone https://github.com/dripcap/dripcap-helper-gold.git dripcap-helper
cp ./dripcap-darwin/dripcap.app/Contents/Resources/app/node_modules/goldfilter/build/goldfilter dripcap-helper/
plutil -replace 'CFBundleVersion' -string `node -p "require('../package.json').version"` dripcap-helper/DripcapHelper/Info.plist
cd dripcap-helper
xcodebuild -configuration Release
cd ..

cp -r ./dripcap-helper/build/Release/Dripcap\ Helper\ Installer.app ./dripcap-darwin/dripcap.app/Contents/Frameworks
codesign --deep --force --verify --verbose --sign "$DRIPCAP_DARWIN_SIGN" ./dripcap-darwin/dripcap.app/Contents/Frameworks/*
codesign --deep --force --verify --verbose --sign "$DRIPCAP_DARWIN_SIGN" "./dripcap-darwin/dripcap.app"
ditto -c -k --sequesterRsrc --keepParent ./dripcap-darwin/dripcap.app ../dripcap-darwin-amd64.zip

cd ..
npm install --depth 0 -g appdmg
appdmg travis/appdmg.json dripcap-darwin-amd64.dmg
