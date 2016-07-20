{EventEmitter} = require('events')
Session = require('./session')
config = require('./config')

class SessionInterface extends EventEmitter
  constructor: (@parent) ->
    @list = []
    @_dissectors = []
    @_streamDissectors = []
    @_classes = []

  registerDissector: (namespaces, path) ->
    @_dissectors.push({namespaces: namespaces, path: path})

  registerStreamDissector: (namespaces, path) ->
    @_streamDissectors.push({namespaces: namespaces, path: path})

  registerClass: (name, path) ->
    @_classes.push({name: name, path: path})

  unregisterDissector: (path) ->
    index = @_dissectors.find (e) ->
      e.path == path
    if index?
      @_dissectors.splice(index, 1)

  unregisterStreamDissector: (path) ->
    index = @_streamDissectors.find (e) ->
      e.path == path
    if index?
      @_streamDissectors.splice(index, 1)

  unregisterClass: (path) ->
    index = @_classes.find (e) ->
      e.path == path
    if index?
      @_classes.splice(index, 1)

  create: (iface, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(iface, options) if iface?

    tasks = []
    for cls in @_classes
      do (cls=cls) ->
        tasks.push(sess.addClass(cls.name, cls.path))
    for dec in @_dissectors
      do (dec=dec) ->
        tasks.push(sess.addDissector(dec.namespaces, dec.path))
    for dec in @_streamDissectors
      do (dec=dec) ->
        tasks.push(sess.addStreamDissector(dec.namespaces, dec.path))
    Promise.all(tasks).then ->
      dripcap.pubsub.pub 'core:capturing-settings', {iface: iface, options: options}
      sess

module.exports = SessionInterface
