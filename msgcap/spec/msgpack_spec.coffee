msgpack = require('../msgpack')
stream = require('stream')
fs = require('fs')

buf = new Buffer([130, 167, 99, 111, 109, 112, 97, 99, 116, 195, 166, 115, 99, 104, 101, 109, 97, 0])
obj =
  compact: true
  schema: [0, null, "test", "いろはにほへとちりぬるを"]
  empty: [{},[]]
  large: 3312760687
  date: new Date()

describe "msgpack.decode()", ->
  it "decodes a Buffer to an object", ->
    expect(msgpack.decode(buf)).toEqual({compact: true, schema: 0})

describe "msgpack.encode()", ->
  it "encodes an object to a Buffer", ->
    expect(msgpack.decode(msgpack.encode(obj))).toEqual(obj)

describe "msgpack.Decoder", ->
  s = new stream.Readable()
  s._read = ->

  array = []
  beforeEach (done) ->
    decoder = new msgpack.Decoder(s)
    decoder.on 'data', (data) ->
      array.push data
      done() if array.length >= 6

    for i in [0..5]
      s.push(buf.slice(0, i))
      s.push(buf.slice(i))

  it "decodes objects from a Stream", (done) ->
    expect(array).toEqual [
      {compact: true, schema: 0}
      {compact: true, schema: 0}
      {compact: true, schema: 0}
      {compact: true, schema: 0}
      {compact: true, schema: 0}
      {compact: true, schema: 0}
    ]
    done()

describe "msgpack.Decoder", ->
  s = new stream.Readable()
  s._read = ->

  array = []
  beforeEach (done) ->
    decoder = new msgpack.Decoder(s)
    decoder.on 'data', (data) ->
      array.push data

    s.push fs.readFileSync(__dirname + '/partial.bin')
    setTimeout (-> done()), 0

  it "decodes objects from a Stream", (done) ->
    expect(array.length).toEqual 3
    done()
