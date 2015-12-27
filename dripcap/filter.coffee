EventEmitter = require('events')
parse = require('./filter-parse')
msgpack = require('msgcap')
browserify = require ('browserify')
coffeeify = require ('coffeeify')

objurl = ''

bundle = browserify
  extensions: ['.coffee']

bundle.transform coffeeify
bundle.add __dirname + '/filter-worker.coffee'

loadworker = new Promise (res) ->
  bundle.bundle (error, result) ->
    throw error if error?
    res window.URL.createObjectURL(new Blob([result], {type: "text/javascript"}))

class Filter extends EventEmitter
  constructor: (filter) ->
    parse(filter)
    @_count = 0
    @_packets = {}

    @_loadWorker = loadworker.then (obj) =>
      @_worker = new Worker(obj)
      @_worker.postMessage cmd: 'configure', filter: filter
      @_worker.addEventListener 'message', (e) =>
        if e.data.cmd == 'result'
          if @_packets[e.data.id]?
            packet = @_packets[e.data.id]
            delete @_packets[e.data.id]
            if e.data.match
              @emit 'filtered', packet
      Promise.resolve()

  process: (packet) ->
    @_loadWorker.then =>
      array = new Uint8Array msgpack.encode(packet)
      @_worker.postMessage cmd: 'process', packet: array.buffer, id: @_count
      @_packets[@_count] = packet
      @_count++

  terminate: ->
    @_worker.terminate()

module.exports = Filter
