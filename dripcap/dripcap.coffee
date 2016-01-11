config = require('./config')
$ = require('jquery')
PaperFilter = require('paperfilter')
{EventEmitter} = require('events')

PubSub = require('./pubsub')
SessionInterface = require('./session-interface')
ThemeInterface = require('./theme-interface')
KeybindInterface = require('./keybind-interface')
PackageInterface = require('./package-interface')
MenuInterface = require('./menu-interface')

class ActionInterface extends EventEmitter
  constructor: (@parent) ->

class EventInterface extends EventEmitter
  constructor: (@parent) ->

class Dripcap extends EventEmitter

  getInterfaceList: ->
    filter = new PaperFilter
    filter.list()

  constructor: (@profile) ->
    global.dripcap = @

  _init: ->
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

instance = null

module.exports = (prof) ->
  if prof?
    instance = new Dripcap prof
    instance._init()
  instance
