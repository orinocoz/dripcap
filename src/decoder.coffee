require('babel-core/register')(ignore: /.+\/node_modules\/(?!dripper).+\/.+.js/)
require('coffee-script/register')
require('dripper/type')
_ = require('underscore')
net = require('net')
msgpack = require('msgcap')
PaperFilter = require('paperfilter')

class DecoderMap
  constructor: ->
    @_map = {}

  addDecoder: (decoder) ->
    for p in decoder.lowerLayers
      unless @_map[p]
        @_map[p] = []
      @_map[p].push decoder

  analyze: (packet) =>
    Promise.resolve().then =>
      prom = Promise.resolve(packet)
      if array = @_map[_.last(packet.layers).namespace]
        for decoder in array
          prom = do (decoder) ->
            prom.then ->
              new Promise (res, rej) ->
                process.nextTick ->
                  decoder.analyze(packet).then rej, res
      prom = prom.then -> Promise.resolve(packet)
      prom.then (packet) ->
        Promise.resolve(packet)
      , (packet) =>
        @analyze(packet)

class Session
  constructor: (@filterPath) ->
    @_captures = []
    @_filters = []
    @_decoderMap = new DecoderMap()

  load: (decoder) ->
    klass = require(decoder)
    @_decoderMap.addDecoder(new klass)

  connect: (sock) ->
    @_conn.end() if @_conn?
    @_conn = net.createConnection sock

  capture: (option) ->
    @_captures.push option

  start: ->
    @stop()
    for c in @_captures
      f = new PaperFilter
      f.on 'packet', (packet) =>
        @_decoderMap.analyze(packet).then (packet) =>
          @_conn.write msgpack.encode(packet)

      f.start(c.iface, c.options)
      @_filters.push f

  stop: ->
    for f in @_filters
      f.stop()
      f.removeAllListeners()
    @_filters = []

global.session = new Session
