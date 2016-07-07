{EventEmitter} = require('events')
Session = require('./session')
config = require('./config')

class SessionInterface extends EventEmitter
  constructor: (@parent) ->
    @list = []
    @_dissectors = []
    @_classes = []

  registerDecoder: (dec) ->

  unregisterDecoder: (dec) ->

  registerDissector: (namespaces, path) ->
    @_dissectors.push({namespaces: namespaces, path: path})

  registerClass: (name, path) ->
    @_classes.push({name: name, path: path})

  create: (ifs, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(ifs, options) if ifs?
    for dec in @_dissectors
      sess.addDissector dec.namespaces, dec.path
    for cls in @_classes
      sess.addClass cls.name, cls.path
    sess

module.exports = SessionInterface
