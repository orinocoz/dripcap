EventEmitter = require('events')
parse = require('./filter-parse')
msgpack = require('msgcap')

class Filter extends EventEmitter
  constructor: (filter) ->
    parse(filter)
    @_count = 0
    @_packets = {}
    @_worker = new Worker(__dirname + '/filter-worker-bundle.js')
    @_worker.postMessage cmd: 'configure', filter: filter
    @_worker.addEventListener 'message', (e) =>
      if e.data.cmd == 'result'
        if @_packets[e.data.id]?
          packet = @_packets[e.data.id]
          delete @_packets[e.data.id]
          if e.data.match
            @emit 'filtered', packet

  process: (packet) ->
    array = new Uint8Array msgpack.encode(packet)
    @_worker.postMessage cmd: 'process', packet: array.buffer, id: @_count
    @_packets[@_count] = packet
    @_count++

  terminate: ->
    @_worker.terminate()

module.exports = Filter
