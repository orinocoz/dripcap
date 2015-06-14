$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class PacketListView

  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('packet-list-view').then (pkg) =>
      $ =>
        panel = $('[riot-tag=packet-list-view]').closest('.panel.root').data('panel')
        m = $('<div class="wrapper" />').attr 'tabIndex', '0'
        panel.right(m)
        @view = riot.mount(m[0], 'packet-view')[0]

        dripcap.session.on 'created', (session) =>
          @view.set(null)
          @view.update()

        dripcap.pubsub.sub 'PacketListView:select', (pkt) =>
          @view.set(pkt)
          @view.update()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = PacketListView
