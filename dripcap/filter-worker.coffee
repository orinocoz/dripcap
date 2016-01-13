Packet = require('./packet')
msgpack = require('msgcap')
parse = require('./filter-parse')
require('./type')

self.addEventListener 'message', (e) ->
  switch e.data.cmd
    when 'configure'
      @filter = parse e.data.filter
    when 'process'
      pkt = new Packet msgpack.decode(new Buffer(e.data.packet))
      self.postMessage cmd: 'result', match: @filter(pkt), id: e.data.id
