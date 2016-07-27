brew update
brew install nvm gpg v8

mkdir ~/.nvm
export NVM_DIR=~/.nvm
. $(brew --prefix nvm)/nvm.sh

nvm install $NODE_VERSION
nvm use --delete-prefix $NODE_VERSION

export GOROOT=/usr/local/opt/go/libexec
export GOPATH=$HOME/gosrc
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

export CC=clang
export CXX=clang++
