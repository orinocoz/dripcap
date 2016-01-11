class UTP
  activate: ->
    dripcap.session.registerDecoder("#{__dirname}/utp")

  deactivate: ->
    dripcap.session.unregisterDecoder("#{__dirname}/utp")

module.exports = UTP
