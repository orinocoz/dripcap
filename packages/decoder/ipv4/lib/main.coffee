class IPv4
  activate: ->
    dripcap.session.on 'created', @callback = (session) ->
      session.addDecoder("#{__dirname}/ipv4")

  deactivate: -> dripcap.session.removeListener 'created', @callback

module.exports = IPv4
