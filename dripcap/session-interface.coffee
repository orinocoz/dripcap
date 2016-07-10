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

  create: (ifs, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(ifs, options) if ifs?

    prom = Promise.resolve();
    for cls in @_classes
      prom = prom.then ->
        sess.addClass cls.name, cls.path
    for dec in @_dissectors
      prom = prom.then ->
        sess.addDissector dec.namespaces, dec.path
    sess

module.exports = SessionInterface
