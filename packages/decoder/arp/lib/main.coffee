class ARP
  activate: ->
    dripcap.session.on 'created', (session) ->
      session.addDecoder("#{__dirname}/arp")

  deactivate: ->

module.exports = ARP
