require('coffee-script/register')
app = require('app')
BrowserWindow = require('browser-window')
mkpath = require('mkpath')
config = require('./config')
require('crash-reporter').start(config.crashReporter)

mkpath.sync(config.userPackagePath)
mkpath.sync(config.profilePath)

class Dripcap
  constructor: ->
    @indicator = 0

  newWindow: ->
    options =
      width: 1200
      height: 800
      show: false
      'title-bar-style': 'hidden-inset'

    mainWindow = new BrowserWindow options
    mainWindow.loadUrl 'file://' + __dirname + '/../render.html'

  pushIndicator: ->
    @indicator++
    if @indicator == 1
      if process.platform == 'darwin'
        @indicatorInterval = setInterval =>
          switch @indicator
            when 0
              app.dock.setBadge(" ● ○ ○ ")
            when 1
              app.dock.setBadge(" ○ ● ○ ")
            when 2
              app.dock.setBadge(" ○ ○ ● ")
          @indicator = (@indicator + 1) % 3
        , 500

  popIndicator: ->
    if @indicator > 0
      @indicator--
    if @indicator <= 0
      if process.platform == 'darwin'
        clearInterval @indicatorInterval
        app.dock.setBadge("")

global.dripcap = new Dripcap

if process.env['DRIPCAP_UI_TEST']?
  require './uitest'
else
  app.on 'window-all-closed', ->
    app.quit()

  app.on 'ready', ->
    dripcap.newWindow()
