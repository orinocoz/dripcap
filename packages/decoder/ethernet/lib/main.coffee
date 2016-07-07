class Ethernet
  activate: ->
    dripcap.session.registerDissector(['::<Ethernet>'], "#{__dirname}/eth.es")
    dripcap.session.registerClass('dripcap/mac', "#{__dirname}/mac.es")
    dripcap.session.registerClass('dripcap/enum', "#{__dirname}/enum.es")

  deactivate: ->

module.exports = Ethernet
