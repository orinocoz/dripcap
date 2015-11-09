path = require('path')
glob = require('glob')
semver = require('semver')
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
_ = require('underscore')

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
      @scheme = @_defaultScheme

    register: (id, scheme) ->
      @registory[id] = scheme
      @pub 'updateRegistory', null, 1

    unregister: (id) ->
      delete @registory[id]
      @pub 'updateRegistory', null, 1

    @property 'scheme',
      get: -> @_scheme
      set: (s) ->
        unless _.isEqual @_scheme, s
          @_scheme = s
          @pub 'update', s, 1

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

  class PackageInterface extends EventEmitter
    constructor: (@parent) ->
      @_loadedPackages = {}

    load: (name) ->
      pkg = @_loadedPackages[name]
      throw new Error "package not found: #{name}" unless pkg?
      pkg.load()

    unload: (name) ->
      pkg = @_loadedPackages[name]
      throw new Error "package not found: #{name}" unless pkg?
      pkg.deactivate()

    updatePackageList: ->
      paths = glob.sync(config.packagePath + '/**/package.json')
      paths = paths.concat glob.sync(config.userPackagePath + '/**/package.json')

      for p in paths
        try
          pkg = new Package(p)

          if _.isObject(conf = @parent.profile.package[pkg.name])
            _.extendOwn pkg.config, conf

          if (loaded = @_loadedPackages[pkg.name])?
            if loaded.path != pkg.path
              console.warn "package name conflict: #{pkg.name}"
              continue
            else if semver.gte loaded.version, pkg.version
              continue
            else
              loaded.deactivate()
          @_loadedPackages[pkg.name] = pkg
        catch e
          console.warn "failed to load #{pkg.name}/package.json : #{e}"

      for k, pkg of @_loadedPackages
        if pkg.config.enabled
          pkg.activate()
          pkg.updateTheme @parent.theme.scheme

    updateTheme: (scheme) ->
      for k, pkg of @_loadedPackages
        if pkg.config.enabled
          pkg.updateTheme scheme

    rebuild: (path) ->
      ver = config.electronVersion
      rebuild.installNodeHeaders(ver).then ->
        rebuild.rebuildNativeModules(ver, config.packagePath).then ->
          rebuild.rebuildNativeModules(ver, config.userPackagePath)

    install: (name) ->
      npm.load production: true, =>
        npm.commands.install config.userPackagePath, [name], =>
          @parent.updatePackageList()

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
      @_menuTmpl = []

    add: (path, template) ->
      merge = (path, root, template) ->
        root.submenu ?= []
        if path.length == 0
          root.submenu.push template
        else
          label = _.first(path)
          i = _.findIndex root.submenu, (ele) -> ele.label == label
          if i < 0
            root.submenu.push merge(_.rest(path), label: label, submenu: [], template)
          else
            root.submenu[i] = merge(_.rest(path), root.submenu[i], template)
        root

      @_menuTmpl = merge(path, submenu: @_menuTmpl, template).submenu
      @_menu = Menu.buildFromTemplate(_.clone(@_menuTmpl).map action)

      if process.platform != 'darwin'
        remote.getCurrentWindow().setMenu(@_menu)
      else
        Menu.setApplicationMenu(@_menu)

    remove: (path) ->
      merge = (path, root) ->
        if root.submenu? && path.length > 0
          label = _.first(path)
          i = _.findIndex root.submenu, (ele) -> ele.label == label
          if i >= 0
            if path.length == 1
              root.submenu.splice i, 1
            else
              root.submenu[i] = merge(_.rest(path), root.submenu[i])
        root

      @_menuTmpl = merge(path, submenu: @_menuTmpl).submenu
      @_menu = Menu.buildFromTemplate(_.clone(@_menuTmpl).map action)

      if process.platform != 'darwin'
        remote.getCurrentWindow().setMenu(@_menu)
      else
        Menu.setApplicationMenu(@_menu)

    get: (path) ->
      return null unless path.length > 0
      menu =
        submenu:
          items:
            @_menu.items
      for p in path
        return null unless menu.submenu?
        i = _.findIndex menu.submenu.items, (ele) -> ele.label == p
        return null if i < 0
        menu = menu.submenu.items[i]
      menu

  getInterfaceList: ->
    filter = new PaperFilter
    filter.list()

  constructor: (@profile) ->
    if global.dripcap?
      throw new Error 'global.dripcap already exists!'
    global.dripcap = @

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

    @package.updatePackageList()
    @profile.init()

    $(window).unload =>
      for k, pkg of @package.loadedPackages
        pkg.deactivate()
      @profile.save()

exports.init = (prof) -> new Dripcap prof
