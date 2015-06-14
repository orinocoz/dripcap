require('coffee-script/register')
require('dripper/type')
_ = require('underscore')
net = require('net')
msgpack = require('msgcap')
PaperFilter = require('paperfilter')

class DecoderMap
  constructor: () ->
    @map = {}

  addDecoder: (decoder) ->
    for p in decoder.lowerLayers
      unless @map[p]
        @map[p] = []
      @map[p].push decoder

  analyze: (packet) =>
    Promise.resolve().then =>
      prom = Promise.resolve(packet)
      if array = @map[_.last(packet.layers).namespace]
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
    @captures = []
    @filters = []
    @decoderMap = new DecoderMap()

  load: (decoder) ->
    klass = require(decoder)
    @decoderMap.addDecoder(new klass)

  connect: (sock) ->
    @conn.end() if @conn?
    @conn = net.createConnection sock

  capture: (option) ->
    @captures.push option

  start: ->
    @stop()
    for c in @captures
      f = new PaperFilter
      f.on 'packet', (packet) =>
        @decoderMap.analyze(packet).then (packet) =>
          @conn.write msgpack.encode(packet)

      f.start(c.iface, c.options)
      @filters.push f

  stop: ->
    for f in @filters
      f.stop()
      f.removeAllListeners()
    @filters = []

global.session = new Session
