class ARP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/arp")

  deactivate: ->
    dripcap.session.unregisteDecoder("#{__dirname}/arp")

module.exports = ARP
