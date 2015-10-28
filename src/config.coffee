path = require('path')
homePath = path.join process.env['HOME'], '/.dripcap'

conf =
  homePath: homePath
  userPackagePath: path.join homePath, '/packages'
  profilePath: path.join homePath, '/profiles'
  packagePath: path.join path.dirname(__dirname), '/packages'
  electronVersion: '0.33.8'
  crashReporter:
    productName: 'dripcap'
    companyName: 'dripcap'
    submitUrl: 'http://report.h2so5.net/report.php'
    autoSubmit: false

module.exports = conf
