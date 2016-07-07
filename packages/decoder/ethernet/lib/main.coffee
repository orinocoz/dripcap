class Ethernet
  activate: ->
    dripcap.session.registerClass('dripcap/mac', "#{__dirname}/mac.es")
    dripcap.session.registerClass('dripcap/enum', "#{__dirname}/enum.es")
    #dripcap.session.registerClass('dripcap/eth/type', "#{__dirname}/eth_type.es")
    dripcap.session.registerDissector(['::<Ethernet>'], "#{__dirname}/eth.es")

  deactivate: ->

module.exports = Ethernet
