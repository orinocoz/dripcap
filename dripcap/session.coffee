{EventEmitter} = require('events')
Packet = require('dripcap/packet')
GoldFilter = require('goldfilter').default;

class Session extends EventEmitter
  constructor: (@_filterPath) ->
    @_pktId = 1

    @_gold = new GoldFilter()
    @_gold.on 'status', (stat) =>
      if stat.packets >= @_pktId
        @_gold.requestPackets(@_pktId, stat.packets)
        @_pktId = stat.packets + 1
        dripcap.pubsub.pub 'core:capturing-status', stat.capturing

    @_gold.on 'packet', (pkt) =>
      @emit 'packet', new Packet(pkt)

  addCapture: (iface, options = {}) ->
    @_settings = {iface: iface, options: options}

  addDissector: (namespaces, path) ->
    @_gold.addDissector(namespaces, path)

  addClass: (name, path) ->
    @_gold.addClass(name, path)

  start: ->
    @_gold.stop().then =>
        @_gold.start(@_settings.iface, @_settings.options)

  stop: ->
    @_gold.stop()

  close: ->
    @_gold.close()

module.exports = Session
