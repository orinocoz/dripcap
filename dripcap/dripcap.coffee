$ = require('jquery')
PaperFilter = require('paperfilter')
{EventEmitter} = require('events')

config = require('./config')
PubSub = require('./pubsub-interface')
ThemeInterface = require('./theme-interface')
KeybindInterface = require('./keybind-interface')
MenuInterface = require('./menu-interface')
PackageInterface = require('./package-interface')
SessionInterface = require('./session-interface')

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
