class UDP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/udp")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/udp")

module.exports = UDP
