class DNS
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/dns")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/dns")

module.exports = DNS
