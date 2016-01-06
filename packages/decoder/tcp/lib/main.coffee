class TCP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/tcp")

  deactivate: ->
    dripcap.session.unregisteDecoder("#{__dirname}/tcp")

module.exports = TCP
