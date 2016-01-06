class IPv4
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ipv4")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/ipv4")

module.exports = IPv4
