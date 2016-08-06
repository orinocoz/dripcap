config = require('./config')
$ = require('jquery')
GoldFilter = require('goldfilter').default;
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
    @_gold.devices()

  constructor: (@profile) ->
    @_gold = new GoldFilter();
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

    @theme.id = theme

    @package.updatePackageList()
    @profile.init()

    $(window).on 'unload', =>
      for k, pkg of @package.loadedPackages
        pkg.deactivate()

instance = null

module.exports = (prof) ->
  if prof?
    instance = new Dripcap prof
    instance._init()
  instance
