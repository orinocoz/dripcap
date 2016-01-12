Component = require('dripcap/component')

class UTP
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.session.registerDecoder("#{__dirname}/utp")

  deactivate: ->
    @comp.destroy()
    dripcap.session.unregisterDecoder("#{__dirname}/utp")

module.exports = UTP
