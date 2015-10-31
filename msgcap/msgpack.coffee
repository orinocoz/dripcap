{EventEmitter} = require('events')

class Decoder extends EventEmitter
  constructor: (@stream) ->
    @stream.on 'data', (chunk) =>
      if @buffer
        buf = new Buffer(@buffer.length + chunk.length)
        @buffer.copy(buf, 0, 0, @buffer.length)
        chunk.copy(buf, @buffer.length, 0, chunk.length)
        @buffer = buf
      else
        @buffer = chunk
      try
        while (true)
          res = decodeNext(@buffer)
          @emit('data', res[0])
          @buffer = res[1]
      catch e
        unless e instanceof EOSError
          throw e

class EOSError
  constructor: ->

assertLength = (buf, len) ->
  throw new EOSError if buf.length < len

decodeArray = (buf, len) ->
  array = []
  if len > 0
    for i in [1..len]
      res = decodeNext(buf)
      buf = res[1]
      array.push(res[0])
  [array, buf]

decodeMap = (buf, len) ->
  obj = {}
  if len > 0
    for i in [1..len]
      key = decodeNext(buf)
      buf = key[1]
      value = decodeNext(buf)
      buf = value[1]
      obj[key[0]] = value[0]
  [obj, buf]

decodeNext = (buf) ->
  assertLength(buf, 1)
  switch buf[0]
    when 0xc0
      [null, buf.slice(1)]
    when 0xc2
      [false, buf.slice(1)]
    when 0xc3
      [true, buf.slice(1)]
    when 0xcc
      assertLength(buf, 2)
      [buf.readUInt8(1, true), buf.slice(2)]
    when 0xcd
      assertLength(buf, 3)
      [buf.readUInt16BE(1, true), buf.slice(3)]
    when 0xce
      assertLength(buf, 5)
      [buf.readUInt32BE(1, true), buf.slice(5)]
    when 0xcf
      assertLength(buf, 9)
      [buf.readUInt32BE(5, true), buf.slice(9)]
    when 0xd0
      assertLength(buf, 2)
      [buf.readInt8(1, true), buf.slice(2)]
    when 0xd1
      assertLength(buf, 3)
      [buf.readInt16BE(1, true), buf.slice(3)]
    when 0xd2
      assertLength(buf, 5)
      [buf.readInt32BE(1, true), buf.slice(5)]
    when 0xd3
      assertLength(buf, 9)
      [buf.readInt32BE(5, true), buf.slice(9)]
    when 0xca
      assertLength(buf, 5)
      [buf.readFloatBE(1, true), buf.slice(5)]
    when 0xcb
      assertLength(buf, 9)
      [buf.readDoubleBE(1, true), buf.slice(9)]
    when 0xd9
      assertLength(buf, 2)
      len = buf.readUInt8(1, true)
      assertLength(buf, len + 2)
      [buf.slice(2, 2 + len).toString(), buf.slice(len + 2)]
    when 0xda
      assertLength(buf, 3)
      len = buf.readUInt16BE(1, true)
      assertLength(buf, len + 3)
      [buf.slice(3, 3 + len).toString(), buf.slice(len + 3)]
    when 0xdb
      assertLength(buf, 5)
      len = buf.readUInt32BE(1, true)
      assertLength(buf, len + 5)
      [buf.slice(5, 5 + len).toString(), buf.slice(len + 5)]
    when 0xc4
      assertLength(buf, 2)
      len = buf.readUInt8(1, true)
      assertLength(buf, len + 2)
      [buf.slice(2, 2 + len), buf.slice(len + 2)]
    when 0xc5
      assertLength(buf, 3)
      len = buf.readUInt16BE(1, true)
      assertLength(buf, len + 3)
      [buf.slice(3, 3 + len), buf.slice(len + 3)]
    when 0xc6
      assertLength(buf, 5)
      len = buf.readUInt32BE(1, true)
      assertLength(buf, len + 5)
      [buf.slice(5, 5 + len), buf.slice(len + 5)]
    when 0xdc
      assertLength(buf, 3)
      len = buf.readUInt16BE(1, true)
      decodeArray(buf.slice(3), len)
    when 0xdd
      assertLength(buf, 5)
      len = buf.readUInt32BE(1, true)
      decodeArray(buf.slice(5), len)
    when 0xde
      assertLength(buf, 3)
      len = buf.readUInt16BE(1, true)
      decodeMap(buf.slice(3), len)
    when 0xdf
      assertLength(buf, 5)
      len = buf.readUInt32BE(1, true)
      decodeMap(buf.slice(5), len)
    when 0xc9
      assertLength(buf, 6)
      len = buf.readUInt32BE(1, true)
      type = buf.readInt8(5, true)
      assertLength(buf, len + 6)
      if type == 0x0d
        [new Date(decode(buf.slice(6, 6 + len))), buf.slice(len + 6)]
      else if type == 0x78
        array = decode(buf.slice(6, 6 + len))
        if klass = ext[array[0]]
          args = [null].concat(array[1])
          obj = new (Function.prototype.bind.apply(klass, args))
          [obj, buf.slice(len + 6)]
        else
          [array, buf.slice(len + 6)]
      else
        [buf.slice(6, 6 + len), buf.slice(len + 6)]

    else
      switch
        when (buf[0] & 0b10000000) == 0
          [buf[0] & 0b01111111, buf.slice(1)]
        when (buf[0] & 0b11100000) == 0b11100000
          [-(buf[0] & 0b00011111), buf.slice(1)]
        when (buf[0] & 0b11100000) == 0b10100000
          len = (buf[0] & 0b00011111)
          assertLength(buf, len + 1)
          [buf.slice(1, 1 + len).toString(), buf.slice(len + 1)]
        when (buf[0] & 0b11110000) == 0b10010000
          len = (buf[0] & 0b00001111)
          decodeArray(buf.slice(1), len)
        when (buf[0] & 0b11110000) == 0b10000000
          len = (buf[0] & 0b00001111)
          decodeMap(buf.slice(1), len)
        else
          throw new SyntaxError "unexpected token: 0x#{buf[0].toString(16)}"

decode = (buf) ->
  try
    res = decodeNext(buf)
    throw new SyntaxError "extra bytes after an object" if res[1].length > 0
    res[0]
  catch e
    if e instanceof EOSError
      throw new SyntaxError "unexpected EOS"
    else
      throw e

class Encoder extends EventEmitter
  constructor: (@stream) ->

  encode: (obj) ->
    @stream.write encode(obj)

encode = (obj) ->
  buf = new Buffer(0)
  append = (buf, obj) ->
    Buffer.concat [buf, new Buffer(obj)]

  switch typeof obj
    when "undefined"
      buf = append buf, [0xc0]

    when "boolean"
      if obj
        buf = append buf, [0xc3]
      else
        buf = append buf, [0xc2]

    when "number"
      if obj % 1 == 0
        if obj > 2147483647
          buf = append buf, [0xce, 0x0, 0x0, 0x0, 0x0]
          buf.writeUInt32BE(obj, buf.length - 4)
        else
          buf = append buf, [0xd2, 0x0, 0x0, 0x0, 0x0]
          buf.writeInt32BE(obj, buf.length - 4)
      else
        buf = append buf, [0xcb, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]
        buf.writeDoubleBE(obj, buf.length - 8)

    when "string"
      buf = append buf, [0xdb, 0x0, 0x0, 0x0, 0x0]
      buf.writeUInt32BE(obj.length, buf.length - 4)
      buf = append buf, obj

    when "object"
      if Array.isArray obj
        buf = append buf, [0xdd, 0x0, 0x0, 0x0, 0x0]
        buf.writeUInt32BE(obj.length, buf.length - 4)
        for i in obj
          buf = append buf, encode(i)

      else if Buffer.isBuffer obj
        buf = append buf, [0xc6, 0x0, 0x0, 0x0, 0x0]
        buf.writeUInt32BE(obj.length, buf.length - 4)
        buf = append buf, obj

      else if obj instanceof Date
        extbuf = encode(obj.toISOString())
        buf = append buf, [0xc9, 0x0, 0x0, 0x0, 0x0, 0x0]
        buf.writeUInt32BE(extbuf.length, buf.length - 5)
        buf.writeInt8(0x0d, buf.length - 1)
        buf = append buf, extbuf
        buf

      else if obj == null
        buf = append buf, [0xc0]

      else if klass = ext[obj.constructor.name]
        extbuf = encode([obj.constructor.name, obj.toMsgpack()])
        buf = append buf, [0xc9, 0x0, 0x0, 0x0, 0x0, 0x0]
        buf.writeUInt32BE(extbuf.length, buf.length - 5)
        buf.writeInt8(0x78, buf.length - 1)
        buf = append buf, extbuf
        buf

      else
        buf = append buf, [0xdf, 0x0, 0x0, 0x0, 0x0]
        buf.writeUInt32BE(Object.keys(obj).length, buf.length - 4)
        for k in Object.keys(obj)
          buf = append buf, encode(k)
          buf = append buf, encode(obj[k])

    when 'function'
      buf = append buf, [0xc0]

    else
      throw new TypeError "unsupported type: #{typeof obj}"
  buf

ext = {}

register = (klass) ->
  ext[klass.name] = klass

exports.Decoder = Decoder
exports.Encoder = Encoder
exports.decode = decode
exports.encode = encode
exports.register = register
