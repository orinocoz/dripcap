sudo apt-get remove libicu-dev
wget `curl https://api.github.com/repos/dripcap/libv8/releases | jq -r '.[0].assets[0].browser_download_url'`
sudo dpkg -i --force-overwrite v8-linux-amd64.deb
