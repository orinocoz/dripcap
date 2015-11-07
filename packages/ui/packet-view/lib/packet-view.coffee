$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class PacketListView

  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('main-view').then (pkg) =>
      $ =>
        m = $('<div class="wrapper" />').attr 'tabIndex', '0'
        pkg.root.panel.center('packet-view', m)
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
