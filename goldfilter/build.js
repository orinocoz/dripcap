const childProcess = require('child_process');

if (process.platform === 'win32') {
  childProcess.execSync('MSBuild goldfilter.sln /t:Rebuild /p:Configuration=Release /m');
} else {
  childProcess.execSync('make -j2 NODEBUG=true');
}
