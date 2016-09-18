const childProcess = require('child_process');

var proc;
if (process.platform === 'win32') {
  if (process.env['NOWINPCAP'] === '1') {
      proc = childProcess.exec('MSBuild goldfilter.sln /p:ForceImportBeforeCppTargets=' + __dirname + '\\nowinpcap.props /clp:ErrorsOnly /t:Rebuild /p:Configuration=Release /m');
  } else {
      proc = childProcess.exec('MSBuild goldfilter.sln /clp:ErrorsOnly /t:Build /p:Configuration=Release /m');
  }
} else {
  proc = childProcess.exec('make -j2 NODEBUG=true');
}
proc.stderr.pipe(process.stderr);
proc.stdout.pipe(process.stdout);
