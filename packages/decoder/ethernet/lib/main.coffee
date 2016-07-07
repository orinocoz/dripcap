class Ethernet
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ethernet")
    dripcap.session.registerDissector(['::<Ethernet>'], "#{__dirname}/eth.es")
    dripcap.session.registerClass('dripcap/mac', "#{__dirname}/mac.es")
    dripcap.session.registerClass('dripcap/enum', "#{__dirname}/enum.es")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/ethernet")

module.exports = Ethernet
