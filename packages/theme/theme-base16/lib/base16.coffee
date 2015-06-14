class Base16
  activate: ->
    dripcap.theme.register 'base16-mocha-dark',
      name: "Mocha dark"
      less: ["#{__dirname}/../less/mocha-dark.less"]

    dripcap.theme.register 'base16-ocean-light',
      name: "Ocean light"
      less: ["#{__dirname}/../less/ocean-light.less"]

  deactivate: ->
    dripcap.theme.unregister 'base16-mocha-dark'

module.exports = Base16
