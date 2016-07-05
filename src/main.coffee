require('coffee-script/register')
require("babel-register")({
    presets : [ "es2015" ],
    extensions : [ ".es" ]
})

app = require('electron').app
updater = require('./updater')
dialog = require('electron').dialog
BrowserWindow = require('electron').BrowserWindow
mkpath = require('mkpath')
config = require('dripcap/config')

mkpath.sync(config.userPackagePath)
mkpath.sync(config.profilePath)

class Dripcap
  constructor: ->
    @_indicator = 0

  checkForUpdates: ->
    autoUpdater = require('electron').autoUpdater
    autoUpdater.on 'error', (e) =>
      console.warn e.toString()
      setTimeout @checkForUpdates, 60 * 60 * 1000 * 4
    .on 'checking-for-update', -> console.log('Checking for update')
    .on 'update-available', -> console.log('Update available')
    .on 'update-not-available', =>
      console.log('Update not available')
      setTimeout @checkForUpdates, 60 * 60 * 1000 * 4
    .on 'update-downloaded', ->
      index = dialog.showMessageBox
        message: "Updates Available",
        detail: "Do you want to install a new version now?",
        buttons: ["Restart and Install", "Not Now"]

      if index == 0
        autoUpdater.quitAndInstall()

    updater.createServer (url) ->
      autoUpdater.setFeedURL(url)
      autoUpdater.checkForUpdates()

  newWindow: ->
    options =
      width: 1200
      height: 800
      show: false
      titleBarStyle: 'hidden-inset'

    mainWindow = new BrowserWindow options
    mainWindow.loadURL 'file://' + __dirname + '/../render.html'
    unless process.env['DRIPCAP_UI_TEST']?
      mainWindow.webContents.on 'did-finish-load', ->
        mainWindow.show()

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
    if process.platform == 'darwin'
      dripcap.checkForUpdates()
    dripcap.newWindow()
