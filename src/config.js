import path from 'path'
let homePath = path.join(process.env['HOME'], '/.dripcap')

let conf = {
  homePath: homePath,
  userPackagePath: path.join(homePath, '/packages'),
  profilePath: path.join(homePath, '/profiles'),
  packagePath: path.join(path.dirname(__dirname), '/packages'),
  electronVersion: '0.35.1',
  crashReporter: {
    productName: 'dripcap',
    companyName: 'dripcap',
    submitURL: 'http://report.h2so5.net/report.php',
    autoSubmit: false,
  }
}

export default conf
