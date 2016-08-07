import path from 'path';
import fs from 'fs';
const homePath = path.join(process.env['HOME'], '/.dripcap');

const pkg = JSON.parse(fs.readFileSync(__dirname + '/../../package.json'));

export default {
  homePath: homePath,
  userPackagePath: path.join(homePath, '/packages'),
  profilePath: path.join(homePath, '/profiles'),
  packagePath: path.join(path.dirname(__dirname), '/../packages'),
  electronVersion: pkg.engines.electron,
  version: pkg.version,
  crashReporter: {
    productName: 'dripcap',
    companyName: 'dripcap',
    submitURL: 'http://report.h2so5.net/report.php',
    autoSubmit: false
  }
};
