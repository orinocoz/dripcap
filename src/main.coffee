require('coffee-script/register')
app = require('app')
BrowserWindow = require('browser-window')
mkpath = require('mkpath')
config = require('./config')
require('crash-reporter').start(config.crashReporter)

mkpath.sync(config.userPackagePath)
mkpath.sync(config.profilePath)

if process.env['DRIPCAP_UI_TEST']?
  require './uitest'
else
  app.on 'window-all-closed', ->
    app.quit()

  app.on 'ready', ->
    options =
      width: 1200
      height: 800
      show: false
      'title-bar-style': 'hidden-inset'

    mainWindow = new BrowserWindow options
    mainWindow.loadUrl 'file://' + __dirname + '/../render.html'
