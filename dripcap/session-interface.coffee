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

  registerClass: (path) ->
    @_classes.push(path)

  create: (ifs, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(ifs, options) if ifs?
    for dec in @_dissectors
      sess.addDissector dec.namespaces, dec.path
    for cls in @_classes
      sess.addClass cls
    sess

module.exports = SessionInterface
