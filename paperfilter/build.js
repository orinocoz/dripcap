const childProcess = require('child_process');

if (process.platform === 'win32') {
  childProcess.execSync('go build -ldflags "-linkmode internal" -ldflags "-H=windowsgui" -o bin/paperfilter.exe');
} else {
  childProcess.execSync('go build -o bin/paperfilter');
}
