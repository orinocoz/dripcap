class ARP
  activate: ->
    dripcap.session.on 'created', @callback = (session) ->
      session.addDecoder("#{__dirname}/arp")

  deactivate: -> dripcap.session.removeListener 'created', @callback

module.exports = ARP
