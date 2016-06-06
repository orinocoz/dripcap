msgpack = require('msgpack-lite')
{EventEmitter} = require('events')

codec = msgpack.createCodec()

codec.addExtPacker 0x70, Date, [Number, msgpack.encode]
codec.addExtUnpacker 0x70, (data) -> new Date(msgpack.decode(data))

exports.decode = (data) ->
  msgpack.decode(data, {codec: codec})

exports.encode = (data) ->
  msgpack.encode(data, {codec: codec})

class Decoder extends EventEmitter
  constructor: (stream) ->
    @_dec = msgpack.createDecodeStream({codec: codec})
    @_dec.on 'data', (data) => @emit 'data', data
    stream.pipe @_dec

class Encoder extends EventEmitter
  constructor: (stream) ->
    @_enc = msgpack.createEncodeStream({codec: codec})
    @_enc.pipe stream

  encode: (obj) ->
    @_enc.write obj

exports.Decoder = Decoder
exports.Encoder = Encoder

typeID = 0

exports.register = (func) ->
  codec.addExtPacker typeID, func, (data) ->
    msgpack.encode(data.toMsgpack(), {codec: codec})

  codec.addExtUnpacker typeID, (data) ->
    args = [null].concat(msgpack.decode(data, {codec: codec}))
    new (Function.prototype.bind.apply(func, args))
    
  typeID++
