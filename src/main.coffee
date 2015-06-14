require('coffee-script/register')
app = require('app')
BrowserWindow = require('browser-window')
mkpath = require('mkpath')
config = require('./config')
require('crash-reporter').start(config.crashReporter)

class Dripcap
  constructor: ->

  newWindow: ->
    options =
      width: 1200
      height: 800
      show: false
      'title-bar-style': 'hidden-inset'

    mainWindow = new BrowserWindow options
    mainWindow.loadUrl 'file://' + __dirname + '/../render.html'

  quit: ->
    app.quit()

app.on 'window-all-closed', ->
  app.quit()

app.on 'ready', ->
  global.dripcap = new Dripcap()
  mkpath.sync(config.userPackagePath)
  mkpath.sync(config.profilePath)

  dripcap.newWindow()
