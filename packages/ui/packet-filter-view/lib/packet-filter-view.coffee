$ = require('jquery')
riot = require('riot')
Component = require('dripcap/component')

class PacketFilterView
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        $ =>
          m = $('<div/>')
          @view = riot.mount(m[0], 'packet-filter-view')[0]
          pkg.root.panel.leftSouthFixed(m)
      res()

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.leftSouthFixed()
      @view.unmount()
      @comp.destroy()

module.exports = PacketFilterView
