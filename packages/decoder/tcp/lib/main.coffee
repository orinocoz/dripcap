class TCP
  activate: ->
    dripcap.session.on 'created', @callback = (session) ->
      session.addDecoder("#{__dirname}/tcp")

  deactivate: -> dripcap.session.removeListener 'created', @callback

module.exports = TCP
