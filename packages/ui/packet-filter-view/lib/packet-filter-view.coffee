$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class PacketFilterView
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('main-view').then (pkg) =>
      $ =>
        m = $('<div/>')
        @view = riot.mount(m[0], 'packet-filter-view')[0]
        pkg.root.panel.leftSouthFixed(m)

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = PacketFilterView
