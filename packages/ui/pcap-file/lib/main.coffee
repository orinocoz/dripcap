$ = require('jquery')
fs = require('fs')
remote = require('remote')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')
config = require('./config')

class MainMenu
  activate: ->
    return
    action = (name) ->
      ->
        dripcap.action.emit name

    @menu = (menu, e) ->
      file = new Menu
      file.append new MenuItem label: 'New Window', accelerator: 'CmdOrCtrl+Shift+N', click: action 'core:new-window'
      file.append new MenuItem label: 'Close Window', accelerator: 'CmdOrCtrl+Shift+W', click: action 'core:close-window'
      file.append new MenuItem type: 'separator'
      file.append new MenuItem label: 'Quit', accelerator: 'CmdOrCtrl+Q', click: action 'core:quit'

      edit = new Menu
      if process.platform == 'darwin'
        edit.append new MenuItem label: 'Cut', accelerator: 'Cmd+X', selector: 'cut:'
        edit.append new MenuItem label: 'Copy', accelerator: 'Cmd+C', selector: 'copy:'
        edit.append new MenuItem label: 'Paste', accelerator: 'Cmd+V', selector: 'paste:'
        edit.append new MenuItem label: 'Select All', accelerator: 'Cmd+A', selector: 'selectAll:'
      else
        contents = remote.getCurrentWebContents()
        edit.append new MenuItem label: 'Cut', accelerator: 'Ctrl+X', click: -> contents.cut()
        edit.append new MenuItem label: 'Copy', accelerator: 'Ctrl+C', click: -> contents.copy()
        edit.append new MenuItem label: 'Paste', accelerator: 'Ctrl+V', click: -> contents.paste()
        edit.append new MenuItem label: 'Select All', accelerator: 'Ctrl+A', click: -> contents.selectAll()
      edit.append new MenuItem type: 'separator'
      edit.append new MenuItem label: 'Preferences', accelerator: 'CmdOrCtrl+,', click: action 'core:preferences'

      capturing = dripcap.pubsub.get 'core:capturing-status' ? false
      session = new Menu
      session.append new MenuItem label: 'New Session', accelerator: 'CmdOrCtrl+N', click: action 'core:new-session'
      session.append new MenuItem type: 'separator'
      session.append new MenuItem label: 'Start', enabled: !capturing, click: action 'core:start-sessions'
      session.append new MenuItem label: 'Stop', enabled: capturing, click: action 'core:stop-sessions'

      developer = new Menu
      developer.append new MenuItem label: 'Toggle DevTools', accelerator: 'CmdOrCtrl+Shift+I', click: action 'core:toggle-devtools'
      developer.append new MenuItem label: 'Open User Directory', click: action 'core:open-user-directroy'

      help = new Menu
      help.append new MenuItem label: 'Open Website', click: action 'core:open-website'
      help.append new MenuItem label: 'Show License', click: action 'core:show-license'
      help.append new MenuItem type: 'separator'
      help.append new MenuItem label: 'Version ' + config, enabled: false

      menu.append new MenuItem label: 'File', submenu: file, type: 'submenu'
      menu.append new MenuItem label: 'Edit', submenu: edit, type: 'submenu'
      menu.append new MenuItem label: 'Session', submenu: session, type: 'submenu'
      menu.append new MenuItem label: 'Developer', submenu: developer, type: 'submenu'
      menu

    @helpMenu = (menu, e) ->
      help = new Menu
      help.append new MenuItem label: 'Open Website', click: action 'core:open-website'
      help.append new MenuItem label: 'Show License', click: action 'core:show-license'
      help.append new MenuItem type: 'separator'
      help.append new MenuItem label: 'Version ' + config, enabled: false

      menu.append new MenuItem label: 'Help', submenu: help, type: 'submenu', role: 'help'
      menu

    dripcap.menu.register 'MainMenu: MainMenu', @menu
    dripcap.menu.register 'MainMenu: MainMenu', @helpMenu, -10

    dripcap.theme.sub 'registoryUpdated', ->
      dripcap.menu.updateMainMenu()

    dripcap.pubsub.sub 'core:capturing-status', ->
      dripcap.menu.updateMainMenu()

  deactivate: ->
    dripcap.menu.unregisterMain 'File', @menu

module.exports = MainMenu
