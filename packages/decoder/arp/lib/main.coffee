class ARP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/arp")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/arp")

module.exports = ARP
