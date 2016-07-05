require('coffee-script/register')
require("babel-register")({
    presets : [ "es2015" ],
    extensions : [ ".es" ]
});

require('dripcap/type')
_ = require('underscore')
net = require('net')
msgpack = require('msgcap')
PaperFilter = require('paperfilter')

class DecoderMap
  constructor: ->
    @_map = {}

  addDecoder: (decoder) ->
    for p in decoder.lowerLayers()
      unless @_map[p]
        @_map[p] = []
      @_map[p].push decoder

  analyze: (packet, layers) =>
    Promise.resolve().then =>
      prom = Promise.resolve()
      for ns, layer of layers
        for decoder in @_map[ns] ? []
          prom = do (decoder, layer) =>
            prom.then =>
              decoder.analyze(packet, layer).then (layer) =>
                @analyze(packet, layer.layers)
              , (layer) ->
                Promise.resolve(layer)
      prom

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
    @_msgdec = new msgpack.Decoder @_conn
    @_msgdec.on 'data', (data) =>
      switch data.type
        when 'packet'
          packet = data.body
          @_decoderMap.analyze(packet, packet.layers).then () =>
            @_conn.write msgpack.encode(packet)

  capture: (option) ->
    @_captures.push option

  start: ->
    @stop()
    for c in @_captures
      f = new PaperFilter
      f.on 'packet', (packet) =>
        @_decoderMap.analyze(packet, packet.layers).then () =>
          @_conn.write msgpack.encode(packet)

      f.start(c.iface, c.options)
      @_filters.push f

  stop: ->
    for f in @_filters
      f.stop()
      f.removeAllListeners()
    @_filters = []

global.session = new Session
