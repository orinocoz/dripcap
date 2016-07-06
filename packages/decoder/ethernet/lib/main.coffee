class Ethernet
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ethernet")
    dripcap.session.registerDissector(['::<Ethernet>'], "#{__dirname}/eth.es")
    dripcap.session.registerClass("#{__dirname}/mac.es")
    dripcap.session.registerClass("#{__dirname}/enum.es")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/ethernet")

module.exports = Ethernet
