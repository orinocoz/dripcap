choco install jq curl

curl.exe -s -S -k https://api.github.com/repos/dripcap/libv8/releases | jq -r '(.[0].assets[] | select(.name == \"v8-windows-amd64.deb\")).browser_download_url'
curl.exe -s -S -k https://api.github.com/repos/dripcap/librocksdb/releases | jq -r '(.[0].assets[] | select(.name == \"rocksdb-windows-amd64.deb\")).browser_download_url'
Expand-Archive -Path .\v8-windows-amd64.zip -DestinationPath $env:HOMEPATH -Force
Expand-Archive -Path .\rocksdb-windows-amd64.zip -DestinationPath $env:HOMEPATH -Force

npm config set loglevel error
npm install -g gulp electron babel-cli
npm install babel-plugin-add-module-exports babel-plugin-transform-async-to-generator babel-plugin-transform-es2015-modules-commonjs
npm install
