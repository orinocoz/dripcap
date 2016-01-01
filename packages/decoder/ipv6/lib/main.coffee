class IPv6
  activate: ->
    dripcap.session.on 'created', @callback = (session) ->
      session.addDecoder("#{__dirname}/ipv6")

  deactivate: -> dripcap.session.removeListener 'created', @callback

module.exports = IPv6
