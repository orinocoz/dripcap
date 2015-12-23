path = require('path')
fs = require('fs')
homePath = path.join process.env['HOME'], '/.dripcap'

conf =
  homePath: homePath
  userPackagePath: path.join homePath, '/packages'
  profilePath: path.join homePath, '/profiles'
  packagePath: path.join path.dirname(__dirname), '/packages'
  electronVersion: '0.36.1'
  version: JSON.parse(fs.readFileSync(__dirname + '/../package.json')).version
  crashReporter:
    productName: 'dripcap'
    companyName: 'dripcap'
    submitURL: 'http://report.h2so5.net/report.php'
    autoSubmit: false

module.exports = conf
