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

      dripcap.keybind.bind 'command+shift+n', '!menu', 'core:new-window'
      dripcap.keybind.bind 'command+shift+w', '!menu', 'core:close-window'
      dripcap.keybind.bind 'command+q', '!menu', 'core:quit'
      dripcap.keybind.bind 'command+,', '!menu', 'core:preferences'
      dripcap.keybind.bind 'command+shift+i', '!menu', 'core:toggle-devtools'
      dripcap.keybind.bind 'command+m', '!menu', 'core:window-minimize'
      dripcap.keybind.bind 'command+alt+ctrl+m', '!menu', 'core:window-zoom'

      @fileMenu = (menu, e) ->
        menu.append new MenuItem label: 'New Window', accelerator: dripcap.keybind.get('!menu', 'core:new-window'), click: action 'core:new-window'
        menu.append new MenuItem label: 'Close Window', accelerator: dripcap.keybind.get('!menu', 'core:close-window'), click: action 'core:close-window'
        menu.append new MenuItem type: 'separator'
        menu.append new MenuItem label: 'Quit', accelerator: dripcap.keybind.get('!menu', 'core:quit'), click: action 'core:quit'
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
        menu.append new MenuItem label: 'Preferences', accelerator: dripcap.keybind.get('!menu', 'core:preferences'), click: action 'core:preferences'
        menu

      @devMenu = (menu, e) ->
        menu.append new MenuItem label: 'Toggle DevTools', accelerator: dripcap.keybind.get('!menu', 'core:toggle-devtools'), click: action 'core:toggle-devtools'
        menu.append new MenuItem label: 'Open User Directory', click: action 'core:open-user-directroy'
        menu

      @windowMenu = (menu, e) ->
        menu.append new MenuItem label: 'Minimize', accelerator: dripcap.keybind.get('!menu', 'core:window-minimize'), role: 'minimize'
        if process.platform == 'darwin'
          menu.append new MenuItem label: 'Zoom', accelerator: dripcap.keybind.get('!menu', 'core:window-zoom'), click: action 'core:window-zoom'
          menu.append new MenuItem type: 'separator'
          menu.append new MenuItem label: 'Bring All to Front', accelerator: dripcap.keybind.get('!menu', 'core:window-front'), role: 'front'
        menu

      @helpMenu = (menu, e) ->
        menu.append new MenuItem label: 'Visit Website', click: action 'core:open-website'
        menu.append new MenuItem label: 'Visit Wiki', click: action 'core:open-wiki'
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
      dripcap.menu.registerMain 'Window', @windowMenu
      dripcap.menu.registerMain 'Help', @helpMenu
      dripcap.menu.setMainPriority 'Help', -999

      dripcap.theme.sub 'registoryUpdated', ->
        dripcap.menu.updateMainMenu()

      dripcap.keybind.on 'update', ->
        dripcap.menu.updateMainMenu()

      res()

  deactivate: ->
    dripcap.keybind.unbind 'command+shift+n', '!menu', 'core:new-window'
    dripcap.keybind.unbind 'command+shift+w', '!menu', 'core:close-window'
    dripcap.keybind.unbind 'command+q', '!menu', 'core:quit'
    dripcap.keybind.unbind 'command+,', '!menu', 'core:preferences'
    dripcap.keybind.unbind 'command+shift+i', '!menu', 'core:toggle-devtools'
    dripcap.keybind.unbind 'command+m', '!menu', 'core:window-minimize'
    dripcap.keybind.unbind 'command+alt+ctrl+i', '!menu', 'core:window-zoom'

    if process.platform == 'darwin'
      dripcap.menu.unregisterMain app.getName(), @appMenu
    dripcap.menu.unregisterMain 'File', @fileMenu
    dripcap.menu.unregisterMain 'Edit', @editMenu
    dripcap.menu.unregisterMain 'Developer', @devMenu
    dripcap.menu.unregisterMain 'Window', @windowMenu
    dripcap.menu.unregisterMain 'Help', @helpMenu

module.exports = MainMenu
