Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

underscore = (str) ->
  str.replace /[\s-]+/, '_'
  .replace /([a-z])([A-Z])/, (m, s1, s2) ->
    s1 + '_' + s2.toLowerCase()
  .toLowerCase()

class PayloadSlice
  constructor: (@start, @end) ->
    throw new Error 'expects integer' unless Number.isInteger @start
    throw new Error 'expects integer' unless Number.isInteger @end

  slice: (start = 0, end = @end) ->
    s = Math.min(@start + start, @end)
    e = Math.max(Math.min(@start + end, @end), s)
    new PayloadSlice(s, e)

  apply: (buf) ->
    throw new Error 'expects Buffer' unless buf instanceof Buffer
    buf.slice(@start, @end)

  @property 'length', get: -> @end - @start

  toString: ->
    "#{@length} bytes"

  toJSON: -> [@start, @end]

  toMsgpack: -> [@start, @end]

class Enum
  constructor: (@table, @value) ->
    throw new Error 'expects Object' unless @table instanceof Object
    if @known
      @attrs = {"#{underscore(@name)}": true}

  @property 'name', get: ->
    str = @table[@value]
    str ?= 'unknown'
    str

  @property 'known', get: ->
    @table[@value]?

  toString: ->
    "#{@name} (#{@value})"

  toJSON: -> @toString()

  toMsgpack: ->
    table = {}
    table[@value] = @table[@value] if @table[@value]?
    [table, @value]

  equals: (val) -> val.toString() == @name

class Flags
  constructor: (@table, @value) ->
    throw new Error 'expects Object' unless @table instanceof Object
    throw new Error 'expects integer' unless Number.isInteger @value

    @attrs = {}
    for k, v of @table
      @attrs[underscore(k)] = @get(k)

  get: (key) ->
    if @table[key]?
      !!(@value & @table[key])
    else
      false

  is: (key) ->
    @table[key]? && (@value == @table[key])

  toString: ->
    values = []
    for k of @table
      values.push k if @get k

    if values.length > 0
      "#{values.join ', '} (#{@value})"
    else
      "none (#{@value})"

  toJSON: -> @toString()

  toMsgpack: ->
    table = {}
    for key of @table
      table[key] = @table[key] if !!(@value & @table[key])
    [table, @value]

class MACAddress
  constructor: (@data) ->
    if typeof @data == 'string'
      @data = new Buffer @data.replace(/[:-]/g, ''), 'hex'
    throw new Error 'expects Buffer or String' unless @data instanceof Buffer
    throw new Error 'invalid address length' unless @data.length == 6

  toString: ->
    @data.toString('hex').replace /..(?=.)/g, "$&:"

  toJSON: -> @toString()

  toMsgpack: -> [@data]

  equals: (val) -> (new MACAddress val.toString()).toString() == @toString()

class IPv4Address
  constructor: (@data) ->
    throw new Error 'expects Buffer' unless @data instanceof Buffer
    throw new Error 'invalid address length' unless @data.length == 4

  toString: ->
    "#{@data[0]}.#{@data[1]}.#{@data[2]}.#{@data[3]}"

  toJSON: -> @toString()

  toMsgpack: -> [@data]

  equals: (val) -> val.toString() == @toString()

class IPv6Address
  constructor: (@data) ->
    throw new Error 'expects Buffer' unless @data instanceof Buffer
    throw new Error 'invalid address length' unless @data.length == 16

  toString: ->
    hex = @data.toString('hex')
    str = ''
    for i in [0..7]
      str += hex.substr(i * 4, 4).replace /0{0,3}/, ''
      str += ':'
    str = str.substr(0, str.length - 1)
    seq = str.match /:0:(?:0:)+/g
    if seq?
      seq.sort (a, b) -> b.length - a.length
      str = str.replace seq[0], '::'
    str

  toJSON: -> @toString()

  toMsgpack: -> [@data]

  equals: (val) -> val.toString() == @toString()

class IPv4Host
  constructor: (@addr, @port) ->
    throw new Error 'expects IPv4Address' unless @addr instanceof IPv4Address
    throw new Error 'invalid port' unless 0 <= @port <= 65535

  toString: ->
    "#{@addr}:#{@port}"

  toJSON: -> @toString()

  toMsgpack: -> [@addr, @port]

  equals: (val) -> val.toString() == @toString()

class IPv6Host
  constructor: (@addr, @port) ->
    throw new Error 'expects IPv6Address' unless @addr instanceof IPv6Address
    throw new Error 'invalid port' unless 0 <= @port <= 65535

  toString: ->
    "[#{@addr}]:#{@port}"

  toJSON: -> @toString()

  toMsgpack: -> [@addr, @port]

  equals: (val) -> val.toString() == @toString()

exports.PayloadSlice = PayloadSlice
exports.Enum = Enum
exports.Flags = Flags
exports.MACAddress = MACAddress
exports.IPv4Address = IPv4Address
exports.IPv6Address = IPv6Address
exports.IPv4Host = IPv4Host
exports.IPv6Host = IPv6Host

msgpack = require('msgcap')
msgpack.register PayloadSlice
msgpack.register Enum
msgpack.register Flags
msgpack.register MACAddress
msgpack.register IPv4Address
msgpack.register IPv6Address
msgpack.register IPv4Host
msgpack.register IPv6Host
