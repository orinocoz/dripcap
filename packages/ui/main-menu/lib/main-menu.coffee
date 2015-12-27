$ = require('jquery')
fs = require('fs')
remote = require('remote')
app = remote.require('app')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')

class MainMenu
  activate: ->
    new Promise (res) =>
      action = (name) -> -> dripcap.action.emit name

      @fileMenu = (menu, e) ->
        menu.append new MenuItem label: 'New Window', accelerator: 'CmdOrCtrl+Shift+N', click: action 'core:new-window'
        menu.append new MenuItem label: 'Close Window', accelerator: 'CmdOrCtrl+Shift+W', click: action 'core:close-window'
        menu.append new MenuItem type: 'separator'
        menu.append new MenuItem label: 'Quit', accelerator: 'CmdOrCtrl+Q', click: action 'core:quit'
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
        menu.append new MenuItem label: 'Preferences', accelerator: 'CmdOrCtrl+,', click: action 'core:preferences'
        menu

      @devMenu = (menu, e) ->
        menu.append new MenuItem label: 'Toggle DevTools', accelerator: 'CmdOrCtrl+Shift+I', click: action 'core:toggle-devtools'
        menu.append new MenuItem label: 'Open User Directory', click: action 'core:open-user-directroy'
        menu

      @helpMenu = (menu, e) ->
        menu.append new MenuItem label: 'Open Website', click: action 'core:open-website'
        menu.append new MenuItem label: 'Show License', click: action 'core:show-license'
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
      dripcap.menu.registerMain 'Developer', @devMenu
      dripcap.menu.registerMain 'Help', @helpMenu
      dripcap.menu.setMainPriority 'Help', -999

      dripcap.theme.sub 'registoryUpdated', ->
        dripcap.menu.updateMainMenu()
        
      res()

  deactivate: ->
    if process.platform == 'darwin'
      dripcap.menu.unregisterMain app.getName(), @appMenu
    dripcap.menu.unregisterMain 'File', @fileMenu
    dripcap.menu.unregisterMain 'Edit', @editMenu
    dripcap.menu.unregisterMain 'Developer', @devMenu
    dripcap.menu.unregisterMain 'Help', @helpMenu

module.exports = MainMenu
