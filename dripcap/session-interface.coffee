{EventEmitter} = require('events')
Session = require('./session')
config = require('./config')

class SessionInterface extends EventEmitter
  constructor: (@parent) ->
    @list = []
    @_decoders = {}

  registerDecoder: (dec) ->
    @_decoders[dec] = null

  unregisterDecoder: (dec) ->
    delete @_decoders[dec]

  create: (ifs, options={}) ->
    sess = new Session(config.filterPath)
    sess.addCapture(ifs, options) if ifs?
    for dec of @_decoders
      sess.addDecoder dec
    sess

module.exports = SessionInterface
