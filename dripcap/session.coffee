{EventEmitter} = require('events')
Packet = require('dripcap/packet')
GoldFilter = require('goldfilter').default;

class Session extends EventEmitter
  constructor: (@_filterPath) ->
    @_gold = new GoldFilter()
    @_gold.on 'status', (stat) =>
      dripcap.pubsub.pub 'core:capturing-status', stat.capturing
      dripcap.pubsub.pub 'core:captured-packets', stat.packets
      dripcap.pubsub.pub 'core:filtered-packets', stat.filtered

    @_gold.on 'packet', (pkt) =>
      @emit 'packet', new Packet(pkt)

    @_builtin = Promise.all([
      @addClass('dripcap/mac', "#{__dirname}/builtin/mac.es")
      @addClass('dripcap/enum', "#{__dirname}/builtin/enum.es")
      @addClass('dripcap/flags', "#{__dirname}/builtin/flags.es")
      @addClass('dripcap/ipv4/addr', "#{__dirname}/builtin/ipv4/addr.es")
      @addClass('dripcap/ipv4/host', "#{__dirname}/builtin/ipv4/host.es")
      @addClass('dripcap/ipv6/addr', "#{__dirname}/builtin/ipv6/addr.es")
      @addClass('dripcap/ipv6/host', "#{__dirname}/builtin/ipv6/host.es")
    ])

  requestPackets: (start, end) ->
    @_gold.requestPackets(start, end)

  addCapture: (iface, options = {}) ->
    @_settings = {iface: iface, options: options}

  addDissector: (namespaces, path) ->
    @_gold.addDissector(namespaces, path)

  addClass: (name, path) ->
    @_gold.addClass(name, path)

  setFilter: (name, exp) ->
    @_gold.setFilter(name, exp)

  getFiltered: (name, start, end) ->
    @_gold.getFiltered(name, start, end)

  start: ->
    @_gold.stop().then =>
      @_builtin.then =>
        @_gold.start(@_settings.iface, @_settings.options)

  stop: ->
    @_gold.stop()

  close: ->
    @_gold.close()

module.exports = Session
