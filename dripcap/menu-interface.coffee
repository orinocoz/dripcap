{EventEmitter} = require('events')
_ = require('underscore')
remote = require('electron').remote
Menu = remote.Menu
MenuItem = remote.MenuItem

class MenuInterface extends EventEmitter
  constructor: (@parent) ->
    @_handlers = {}
    @_mainHadlers = {}
    @_mainPriorities = {}

    @_updateMainMenu = _.debounce =>
      root = new Menu()
      keys = Object.keys @_mainHadlers
      keys.sort (a, b) => (@_mainPriorities[b] ? 0) - (@_mainPriorities[a] ? 0)
      for k in keys
        menu = new Menu()
        for h, i in @_mainHadlers[k]
          menu = h.handler.call(@, menu)
          if i < @_mainHadlers[k].length - 1
            menu.append(new MenuItem(type: 'separator'))
        item = label: k, submenu: menu, type: 'submenu'
        switch k
          when 'Help' then item.role = 'help'
          when 'Window' then item.role = 'window'
        root.append new MenuItem item

      if process.platform != 'darwin'
        remote.getCurrentWindow().setMenu(root)
      else
        Menu.setApplicationMenu(root)
    , 100

  register: (name, handler, priority = 0) ->
    @_handlers[name] ?= []
    @_handlers[name].push handler: handler, priority: priority
    @_handlers[name].sort (a, b) -> b.priority - a.priority

  unregister: (name, handler) ->
    @_handlers[name] ?= []
    @_handlers[name] = @_handlers[name].filter (h) -> h.handler != handler

  registerMain: (name, handler, priority = 0) ->
    @_mainHadlers[name] ?= []
    @_mainHadlers[name].push handler: handler, priority: priority
    @_mainHadlers[name].sort (a, b) -> b.priority - a.priority
    @updateMainMenu()

  unregisterMain: (name, handler) ->
    @_mainHadlers[name] ?= []
    @_mainHadlers[name] = @_mainHadlers[name].filter (h) -> h.handler != handler
    @updateMainMenu()

  setMainPriority: (name, priority) ->
    @_mainPriorities[name] = priority

  updateMainMenu: -> @_updateMainMenu()

  popup: (name, self, browserWindow, x, y) ->
    if @_handlers[name]?
      menu = new Menu()
      handlers = @_handlers[name]
      for h, i in handlers
        menu = h.handler.call(self, menu)
        if i < handlers.length - 1
          menu.append(new MenuItem(type: 'separator'))
      menu.popup browserWindow, x, y

module.exports = MenuInterface
