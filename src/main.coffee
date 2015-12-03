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
    @_indicator = 0

  newWindow: ->
    options =
      width: 1200
      height: 800
      show: false
      'title-bar-style': 'hidden-inset'

    mainWindow = new BrowserWindow options
    mainWindow.loadURL 'file://' + __dirname + '/../render.html'

    if process.platform == 'darwin'
      webContents = mainWindow.webContents
      mainWindow.on 'enter-full-screen', ->
        webContents.executeJavaScript("$('#main-view').css('top', '32px')")
      mainWindow.on 'leave-full-screen', ->
        webContents.executeJavaScript("$('#main-view').css('top', '0')")

  pushIndicator: ->
    @_indicator++
    if @_indicator == 1
      if process.platform == 'darwin'
        @_indicatorInterval = setInterval =>
          switch @_indicator
            when 0
              app.dock.setBadge(" ● ○ ○ ")
            when 1
              app.dock.setBadge(" ○ ● ○ ")
            when 2
              app.dock.setBadge(" ○ ○ ● ")
          @_indicator = (@_indicator + 1) % 3
        , 500

  popIndicator: ->
    if @_indicator > 0
      @_indicator--
    if @_indicator <= 0
      if process.platform == 'darwin'
        clearInterval @_indicatorInterval
        app.dock.setBadge("")

global.dripcap = new Dripcap

if process.env['DRIPCAP_UI_TEST']?
  require './uitest'
else
  app.on 'window-all-closed', ->
    app.quit()

  app.on 'ready', ->
    dripcap.newWindow()
