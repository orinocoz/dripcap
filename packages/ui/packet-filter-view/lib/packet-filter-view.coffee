$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class PacketFilterView
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('packet-list-view').then (pkg) =>
      $ =>
        panel = $('[riot-tag=packet-list-view]').closest('.panel.root').data('panel')
        m = $('<div/>')
        @view = riot.mount(m[0], 'packet-filter-view')[0]
        panel.bottomFixed(m)

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = PacketFilterView
