const childProcess = require('child_process');
childProcess.execSync('make -j2 NODEBUG=true');
