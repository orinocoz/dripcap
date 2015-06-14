path = require('path')
homePath = process.env['HOME'] + '/.dripcap'

conf =
  homePath: homePath
  userPackagePath: homePath + '/packages'
  profilePath: homePath + '/profiles'
  packagePath: path.dirname(__dirname) + '/packages'
  electronVersion: '0.33.0'
  crashReporter:
    productName: 'dripcap'
    companyName: 'dripcap'
    submitUrl: 'https://example.com/'
    autoSubmit: false

module.exports = conf
