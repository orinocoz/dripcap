class Ethernet
  activate: ->
    Promise.all([
      dripcap.session.registerClass('dripcap/eth/type', "#{__dirname}/eth_type.es")
    ]).then =>
      dripcap.session.registerDissector(['::<Ethernet>'], "#{__dirname}/eth.es")

  deactivate: ->

module.exports = Ethernet
