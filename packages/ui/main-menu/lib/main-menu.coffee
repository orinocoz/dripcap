$ = require('jquery')
fs = require('fs')
remote = require('remote')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')

class MainMenu
  activate: ->
    action = (name) ->
      ->
        dripcap.action.emit name

    @menu = (menu, e) ->
      file = new Menu
      file.append new MenuItem label: 'New Window', accelerator: 'CmdOrCtrl+Shift+N', click: action 'Core: New Window'
      file.append new MenuItem label: 'Close Window', accelerator: 'CmdOrCtrl+Shift+W', click: action 'Core: Close Window'
      file.append new MenuItem type: 'separator'
      file.append new MenuItem label: 'Quit', accelerator: 'CmdOrCtrl+Q', click: action 'Core: Quit'

      capturing = dripcap.pubsub.get 'Core: Capturing Status'
      capturing ?= false
      session = new Menu
      session.append new MenuItem label: 'New Session', accelerator: 'CmdOrCtrl+N', click: action 'Core: New Session'
      session.append new MenuItem type: 'separator'
      session.append new MenuItem label: 'Start', enabled: !capturing, click: action 'Core: Start Sessions'
      session.append new MenuItem label: 'Stop', enabled: capturing, click: action 'Core: Stop Sessions'

      theme = new Menu
      selectedScheme = 'default'
      for k, v of dripcap.theme.registory
        do (k = k, v = v) ->
          theme.append new MenuItem
            label: v.name
            type: 'radio'
            checked: selectedScheme == k
            click: ->
              selectedScheme = k
              dripcap.theme.scheme = v

      developer = new Menu
      developer.append new MenuItem label: 'Toggle DevTools', accelerator: 'CmdOrCtrl+Shift+I', click: action 'Core: Toggle DevTools'

      help = new Menu
      help.append new MenuItem label: 'Open Website', click: action 'Core: Open Dripcap Website'
      help.append new MenuItem label: 'Show License', click: action 'Core: Show License'
      help.append new MenuItem type: 'separator'
      help.append new MenuItem label: 'Version ' + JSON.parse(fs.readFileSync(__dirname + '/../../../../package.json')).version, enabled: false

      menu.append new MenuItem label: 'File', submenu: file, type: 'submenu'
      menu.append new MenuItem label: 'Session', submenu: session, type: 'submenu'
      menu.append new MenuItem label: 'Theme', submenu: theme, type: 'submenu'
      menu.append new MenuItem label: 'Developer', submenu: developer, type: 'submenu'
      menu

    @helpMenu = (menu, e) ->
      help = new Menu
      help.append new MenuItem label: 'Open Website', click: action 'Core: Open Dripcap Website'
      help.append new MenuItem label: 'Show License', click: action 'Core: Show License'
      help.append new MenuItem type: 'separator'
      help.append new MenuItem label: 'Version ' + JSON.parse(fs.readFileSync(__dirname + '/../../../../package.json')).version, enabled: false

      menu.append new MenuItem label: 'Help', submenu: help, type: 'submenu', role: 'help'
      menu

    dripcap.menu.register 'MainMenu: MainMenu', @menu
    dripcap.menu.register 'MainMenu: MainMenu', @helpMenu, -10

    dripcap.theme.sub 'updateRegistory', ->
      dripcap.menu.updateMainMenu()

    dripcap.pubsub.sub 'Core: Capturing Status', ->
      dripcap.menu.updateMainMenu()

  deactivate: ->
    dripcap.menu.unregister 'MainMenu: MainMenu', @menu
    dripcap.menu.unregister 'MainMenu: MainMenu', @helpMenu

module.exports = MainMenu
