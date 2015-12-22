$ = require('jquery')
fs = require('fs')
remote = require('remote')
app = remote.require('app')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')

class MainMenu
  activate: ->
    action = (name) ->
      ->
        dripcap.action.emit name

    @fileMenu = (menu, e) ->
      menu.append new MenuItem label: 'New Window', accelerator: 'CmdOrCtrl+Shift+N', click: action 'Core: New Window'
      menu.append new MenuItem label: 'Close Window', accelerator: 'CmdOrCtrl+Shift+W', click: action 'Core: Close Window'
      menu.append new MenuItem type: 'separator'
      menu.append new MenuItem label: 'Quit', accelerator: 'CmdOrCtrl+Q', click: action 'Core: Quit'
      menu

    @editMenu = (menu, e) ->
      if process.platform == 'darwin'
        menu.append new MenuItem label: 'Cut', accelerator: 'Cmd+X', selector: 'cut:'
        menu.append new MenuItem label: 'Copy', accelerator: 'Cmd+C', selector: 'copy:'
        menu.append new MenuItem label: 'Paste', accelerator: 'Cmd+V', selector: 'paste:'
        menu.append new MenuItem label: 'Select All', accelerator: 'Cmd+A', selector: 'selectAll:'
      else
        contents = remote.getCurrentWebContents()
        menu.append new MenuItem label: 'Cut', accelerator: 'Ctrl+X', click: -> contents.cut()
        menu.append new MenuItem label: 'Copy', accelerator: 'Ctrl+C', click: -> contents.copy()
        menu.append new MenuItem label: 'Paste', accelerator: 'Ctrl+V', click: -> contents.paste()
        menu.append new MenuItem label: 'Select All', accelerator: 'Ctrl+A', click: -> contents.selectAll()
      menu.append new MenuItem type: 'separator'
      menu.append new MenuItem label: 'Preferences', accelerator: 'CmdOrCtrl+,', click: action 'Core: Preferences'
      menu

    @captureMenu = (menu, e) ->
      capturing = dripcap.pubsub.get 'Core: Capturing Status' ? false
      menu.append new MenuItem label: 'New Session', accelerator: 'CmdOrCtrl+N', click: action 'Core: New Session'
      menu.append new MenuItem type: 'separator'
      menu.append new MenuItem label: 'Start', enabled: !capturing, click: action 'Core: Start Sessions'
      menu.append new MenuItem label: 'Stop', enabled: capturing, click: action 'Core: Stop Sessions'
      menu

    @devMenu = (menu, e) ->
      menu.append new MenuItem label: 'Toggle DevTools', accelerator: 'CmdOrCtrl+Shift+I', click: action 'Core: Toggle DevTools'
      menu.append new MenuItem label: 'Open User Directory', click: action 'Core: Open User Directory'
      menu

    @helpMenu = (menu, e) ->
      menu.append new MenuItem label: 'Open Website', click: action 'Core: Open Dripcap Website'
      menu.append new MenuItem label: 'Show License', click: action 'Core: Show License'
      menu.append new MenuItem type: 'separator'
      menu.append new MenuItem label: 'Version ' + dripcap.config.version, enabled: false
      menu

    if process.platform == 'darwin'
      @appMenu = (menu, e) -> menu
      name = app.getName()
      dripcap.menu.registerMain name, @appMenu
      dripcap.menu.setMainPriority name, 999

    dripcap.menu.registerMain 'File', @fileMenu
    dripcap.menu.registerMain 'Edit', @editMenu
    dripcap.menu.registerMain 'Capture', @captureMenu
    dripcap.menu.registerMain 'Developer', @devMenu
    dripcap.menu.registerMain 'Help', @helpMenu

    dripcap.theme.sub 'registoryUpdated', ->
      dripcap.menu.updateMainMenu()

    dripcap.pubsub.sub 'Core: Capturing Status', ->
      dripcap.menu.updateMainMenu()

  deactivate: ->
    if process.platform == 'darwin'
      dripcap.menu.unregisterMain app.getName(), @appMenu
    dripcap.menu.unregisterMain 'File', @fileMenu
    dripcap.menu.unregisterMain 'Edit', @editMenu
    dripcap.menu.unregisterMain 'Capture', @captureMenu
    dripcap.menu.unregisterMain 'Developer', @devMenu
    dripcap.menu.unregisterMain 'Help', @helpMenu

module.exports = MainMenu
