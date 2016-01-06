class IPv4
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/ipv4")

  deactivate: ->
    dripcap.session.unregisteDecoder("#{__dirname}/ipv4")

module.exports = IPv4
