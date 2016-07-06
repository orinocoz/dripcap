{EventEmitter} = require('events')
Session = require('./session')
config = require('./config')

class SessionInterface extends EventEmitter
  constructor: (@parent) ->
    @list = []
    @_decoders = {}
    @_dissectors = []

  registerDecoder: (dec) ->
    @_decoders[dec] = null

  unregisterDecoder: (dec) ->
    delete @_decoders[dec]

  registerDissector: (namespaces, path) ->
    @_dissectors.push({namespaces: namespaces, path: path})

  create: (ifs, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(ifs, options) if ifs?
    for dec of @_decoders
      sess.addDecoder dec
    for dec in @_dissectors
      sess.addDissector dec.namespaces, dec.path
    sess

module.exports = SessionInterface
