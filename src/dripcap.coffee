path = require('path')
glob = require('glob')
semver = require('semver')
rmdir = require('rmdir')
config = require('./config')
rebuild = require('electron-rebuild')
$ = require('jquery')
Profile = require('./profile')
Package = require('./package')
Session = require('./session')
PaperFilter = require('paperfilter')
Mousetrap = require('mousetrap')
{EventEmitter} = require('events')
npm = require('npm')
remote = require('remote')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')
_ = require('underscore')
fs = require('fs')
zlib = require('zlib')
tar = require('tar')
request = require('request')

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

class PubSub
  constructor: ->
    @_channels = {}

  _getChannel: (name) ->
    unless @_channels[name]?
      @_channels[name] = {queue: [], handlers: []}
    @_channels[name]

  sub: (name, cb) ->
    ch = @_getChannel name
    ch.handlers.push cb
    for data in ch.queue
      do (data=data) ->
        process.nextTick ->
          cb data

  pub: (name, data, queue=0) ->
    ch = @_getChannel name
    for cb in ch.handlers
      do (cb=cb) ->
        process.nextTick ->
          cb data
    ch.queue.push data
    if queue > 0 && ch.queue.length > queue
      ch.queue.splice 0, ch.queue.length - queue

  get: (name, index = 0) ->
    ch = @_getChannel name
    ch.queue[index]

class Dripcap extends EventEmitter
  class SessionInterface extends EventEmitter
    constructor: (@parent) ->
      @list = []

    create: (ifs, options={}) ->
      sess = new Session(config.filterPath)
      sess.addCapture(ifs, options)
      sess

  class ThemeInterface extends PubSub
    constructor: (@parent) ->
      super()
      @registory = {}

      @_defaultScheme =
        name: 'Default'
        less: ["#{__dirname}/../theme.less"]

      @register 'default', @_defaultScheme
      @id = 'default'

    register: (id, scheme) ->
      @registory[id] = scheme
      @pub 'registoryUpdated', null, 1
      if @_id == id
        @scheme = @registory[id]
        @pub 'update', @scheme, 1

    unregister: (id) ->
      delete @registory[id]
      @pub 'registoryUpdated', null, 1

    @property 'id',
      get: -> @_id
      set: (id) ->
        if id != @_id
          @_id = id
          @parent.profile.setConfig 'theme', id
          if @registory[id]?
            @scheme = @registory[id]
            @pub 'update', @scheme, 1

  class KeybindInterface
    constructor: (@parent) ->
      @_commands = {}

    bind: (command, selector, cb) ->
      unless @_commands[command]
        @_commands[command] = {}
        Mousetrap.bind command, (e) =>
          for sel, cb of @_commands[command]
            cb(e) if $(e.target).is sel

      @_commands[command][selector] = cb

    unbind: (command, selector) ->
      if (s = @_commands[command])?
        delete s[selector]
        if Object.keys(s) == 0
          delete @_commands[command]
          Mousetrap.unbind command

  class PackageInterface extends PubSub
    constructor: (@parent) ->
      super()
      @list = {}

    load: (name) ->
      pkg = @list[name]
      throw new Error "package not found: #{name}" unless pkg?
      pkg.load()

    unload: (name) ->
      pkg = @list[name]
      throw new Error "package not found: #{name}" unless pkg?
      pkg.deactivate()

    updatePackageList: ->
      paths = glob.sync(config.packagePath + '/**/package.json')
      paths = paths.concat glob.sync(config.userPackagePath + '/**/package.json')

      for p in paths
        try
          pkg = new Package(p)

          if (loaded = @list[pkg.name])?
            if loaded.path != pkg.path
              console.warn "package name conflict: #{pkg.name}"
              continue
            else if semver.gte loaded.version, pkg.version
              continue
            else
              loaded.deactivate()
          @list[pkg.name] = pkg
        catch e
          console.warn "failed to load #{pkg.name}/package.json : #{e}"

      for k, pkg of @list
        if pkg.config.get('enabled')
          pkg.activate()
          pkg.updateTheme @parent.theme.scheme

      @pub 'Core: Package List Updated', @list

    updateTheme: (scheme) ->
      for k, pkg of @list
        if pkg.config.get('enabled')
          pkg.updateTheme scheme

    rebuild: (path) ->
      ver = config.electronVersion
      rebuild.installNodeHeaders(ver).then ->
        rebuild.rebuildNativeModules(ver, config.packagePath).then ->
          rebuild.rebuildNativeModules(ver, config.userPackagePath)

    install: (name) ->
      pkgpath = path.join(config.userPackagePath, name)
      tarurl = ''

      p = Promise.resolve().then ->
        new Promise (res, rej) ->
          npm.load {production: true, registry: config['package-registory']}, ->
            npm.commands.view [name], (e, data) ->
              try
                throw e if e?
                pkg = data[Object.keys(data)[0]]
                if ver = pkg.engines?.dripcap
                  if semver.satisfies config.version, ver
                    if tarurl = pkg.dist?.tarball
                      res()
                    else
                      throw new Error 'Tarball not found'
                  else
                    throw new Error 'Dripcap version mismatch'
                else
                  throw new Error 'This package is not for dripcap'
              catch e
                rej(e)

      p = p.then =>
        new Promise (res) ->
          fs.stat pkgpath, (e) -> res(e)
        .then (e) =>
          if e?
            Promise.resolve()
          else
            @uninstall(name)

      p = p.then ->
        new Promise (res) ->
          gunzip = zlib.createGunzip()
          extractor = tar.Extract({path: pkgpath, strip: 1})
          request(tarurl).pipe(gunzip).pipe(extractor).on 'finish', -> res()

      p.then =>
        new Promise (res) =>
          npm.commands.install pkgpath, [], =>
            res()
            @updatePackageList()

    uninstall: (name) ->
      pkgpath = path.join(config.userPackagePath, name)
      new Promise (res) ->
        rmdir pkgpath, (err) ->
          throw err if err?
          res()

  class ActionInterface extends EventEmitter
    constructor: (@parent) ->

  class EventInterface extends EventEmitter
    constructor: (@parent) ->

  class MenuInterface extends EventEmitter
    action = (t) ->
      if t.action?
        t.click = -> dripcap.action.emit t.action
      if t.submenu?
        t.submenu = t.submenu.map action
      t

    constructor: (@parent) ->
      @_handlers = {}
      @_mainHadlers = {}
      @_mainPriorities = {}

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

    updateMainMenu: ->
      root = new Menu()
      keys = Object.keys @_mainHadlers
      keys.sort (a, b) => (@_mainPriorities[b] ? 0) - (@_mainPriorities[a] ? 0)
      for k in keys
        menu = new Menu()
        for h in @_mainHadlers[k]
          menu = h.handler.call(@, menu)
        root.append new MenuItem label: k, submenu: menu, type: 'submenu'

      if process.platform != 'darwin'
        remote.getCurrentWindow().setMenu(root)
      else
        Menu.setApplicationMenu(root)

    popup: (name, self, browserWindow, x, y) ->
      if @_handlers[name]?
        menu = new Menu()
        handlers = @_handlers[name]
        for h, i in handlers
          menu = h.handler.call(self, menu)
          if i < handlers.length - 1
            menu.append(new MenuItem(type: 'separator'))
        menu.popup browserWindow, x, y

  getInterfaceList: ->
    filter = new PaperFilter
    filter.list()

  constructor: (@profile) ->
    if global.dripcap?
      throw new Error 'global.dripcap already exists!'
    global.dripcap = @

    theme = @profile.getConfig('theme')

    @config = config
    @session = new SessionInterface @
    @theme = new ThemeInterface @
    @keybind = new KeybindInterface @
    @package = new PackageInterface @
    @action = new ActionInterface @
    @event = new EventInterface @
    @menu = new MenuInterface @
    @pubsub = new PubSub

    filter = new PaperFilter
    filter.setup(config.filterPackPath)

    @theme.sub 'update', (scheme) =>
      @package.updateTheme scheme

    @theme.id = theme

    @package.updatePackageList()
    @profile.init()

    $(window).unload =>
      for k, pkg of @package.loadedPackages
        pkg.deactivate()

exports.init = (prof) -> new Dripcap prof
