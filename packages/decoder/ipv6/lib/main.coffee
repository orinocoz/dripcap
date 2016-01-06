class IPv6
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ipv6")

  deactivate: ->
    dripcap.session.unregisteDecoder("#{__dirname}/ipv6")

module.exports = IPv6
