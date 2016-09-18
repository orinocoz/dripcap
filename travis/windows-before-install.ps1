choco install jq curl

# $url = curl.exe -s -S -k https://api.github.com/repos/dripcap/libv8/releases | jq -r '(.[0].assets[] | select(.name == \"v8-windows-amd64.zip\")).browser_download_url'
$url = "https://github.com/dripcap/libv8/releases/download/4.8.196/v8-windows-amd64.zip"
curl.exe -s -S -k -L -O $url
# $url = curl.exe -s -S -k https://api.github.com/repos/dripcap/librocksdb/releases | jq -r '(.[0].assets[] | select(.name == \"rocksdb-windows-amd64.zip\")).browser_download_url'
$url = "https://github.com/dripcap/librocksdb/releases/download/4.9/rocksdb-windows-amd64.zip"
curl.exe -s -S -k -L -O $url

Expand-Archive -Path .\v8-windows-amd64.zip -DestinationPath $env:HOMEPATH -Force
Expand-Archive -Path .\rocksdb-windows-amd64.zip -DestinationPath $env:HOMEPATH -Force

$env:NOWINPCAP = "1"
Install-Product node ''
npm config set loglevel error
npm install --depth 0 -g gulp electron babel-cli
npm install --depth 0 babel-plugin-add-module-exports babel-plugin-transform-async-to-generator babel-plugin-transform-es2015-modules-commonjs
npm install --depth 0
