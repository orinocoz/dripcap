class UDP
  activate: ->
    dripcap.session.on 'created', @callback = (session) ->
      session.addDecoder("#{__dirname}/udp")

  deactivate: -> dripcap.session.removeListener 'created', @callback

module.exports = UDP
