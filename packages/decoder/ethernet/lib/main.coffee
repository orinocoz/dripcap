class Ethernet
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ethernet")

  deactivate: ->
    dripcap.session.unregisteDecoder("#{__dirname}/ethernet")

module.exports = Ethernet
