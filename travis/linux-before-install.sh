rm -rf ~/.nvm
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.30.2/install.sh | bash
source ~/.nvm/nvm.sh
nvm install $NODE_VERSION
nvm use --delete-prefix $NODE_VERSION

export CXX="g++-4.9"
wget https://socket.moe/storage/libpcap-1.7.4.tar.gz
tar xzf libpcap-1.7.4.tar.gz
(cd libpcap-1.7.4 && ./configure -q --enable-shared=no && make -j2 && sudo make install)

export DISPLAY=':99.0'

sudo apt-get remove libicu-dev
wget `curl https://api.github.com/repos/dripcap/libv8/releases | jq -r '.[0].assets[0].browser_download_url'`
sudo dpkg -i --force-overwrite v8-linux-amd64.deb

export GOPATH=/home/travis/gopath
export GOBIN=/home/travis/gopath/bin
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
