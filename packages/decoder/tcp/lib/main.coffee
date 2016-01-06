class TCP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/tcp")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/tcp")

module.exports = TCP
