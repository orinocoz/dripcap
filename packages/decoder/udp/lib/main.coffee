class UDP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/udp")

  deactivate: ->
    dripcap.session.unregisteDecoder("#{__dirname}/udp")

module.exports = UDP
