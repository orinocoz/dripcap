class Ethernet
  activate: ->
    dripcap.session.on 'created', @callback = (session) ->
      session.addDecoder("#{__dirname}/ethernet")

  deactivate: -> dripcap.session.removeListener 'created', @callback

module.exports = Ethernet
