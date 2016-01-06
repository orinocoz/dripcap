class Ethernet
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ethernet")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/ethernet")

module.exports = Ethernet
