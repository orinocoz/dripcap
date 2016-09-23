brew update
brew install nvm

mkdir ~/.nvm
export NVM_DIR=~/.nvm
. $(brew --prefix nvm)/nvm.sh

nvm install $NODE_VERSION
nvm use --delete-prefix $NODE_VERSION

mkdir ~/.electron
cd ~/.electron && {
  curl -L -O https://github.com/electron/electron/releases/download/v1.4.1/electron-v1.4.1-darwin-x64.zip ;
  curl -L -o SHASUMS256.txt-1.4.1 https://github.com/electron/electron/releases/download/v1.4.1/SHASUMS256.txt ;
  cd -;
}

until npm install --depth 0 -g electron
do
  echo "Try again"
  ls -lah ~/.electron
done

npm install --depth 0 -g gulp babel-cli
npm install babel-plugin-add-module-exports babel-plugin-transform-async-to-generator babel-plugin-transform-es2015-modules-commonjs
npm install --depth 0 || npm install --depth 0

brew update
brew install nvm gpg v8 rocksdb
export PATH=/usr/local/opt/gnupg/libexec/gpgbin:$PATH

export CC=clang
export CXX=clang++
