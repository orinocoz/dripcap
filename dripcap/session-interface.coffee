{EventEmitter} = require('events')
Session = require('./session')
config = require('./config')

class SessionInterface extends EventEmitter
  constructor: (@parent) ->
    @list = []
    @_dissectors = []
    @_classes = []

  registerDissector: (namespaces, path) ->
    @_dissectors.push({namespaces: namespaces, path: path})

  registerClass: (name, path) ->
    @_classes.push({name: name, path: path})

  unregisterDissector: (path) ->
    index = @_dissectors.find (e) ->
      e.path == path
    if index?
      @_dissectors.splice(index, 1)

  unregisterClass: (path) ->
    index = @_classes.find (e) ->
      e.path == path
    if index?
      @_classes.splice(index, 1)

  create: (ifs, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(ifs, options) if ifs?

    tasks = []
    for cls in @_classes
      do (cls=cls) ->
        tasks.push(sess.addClass(cls.name, cls.path))
    for dec in @_dissectors
      do (dec=dec) ->
        tasks.push(sess.addDissector(dec.namespaces, dec.path))
    Promise.all(tasks).then ->
      sess

module.exports = SessionInterface
