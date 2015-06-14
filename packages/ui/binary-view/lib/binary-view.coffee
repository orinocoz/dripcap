$ = require('jquery')
riot = require('riot')
{Component, Panel} = require('dripper/component')

class BinaryView

  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('packet-view').then (pkg) =>
      $ =>
        panel = $('[riot-tag=packet-view]').closest('.panel.root').data('panel')
        pview = panel.right()

        panel2 = new Panel
        panel.right(panel2.root)

        m = $('<div class="wrapper" />').attr 'tabIndex', '0'
        panel2.center(pview)
        panel2.bottom(m)

        @view = riot.mount(m[0], 'binary-view')[0]
        ulhex = $(@view.root).find('.hex')
        ulascii = $(@view.root).find('.ascii')

        dripcap.session.on 'created', (session) ->
          ulhex.empty()
          ulascii.empty()

        dripcap.pubsub.sub 'PacketView:range', (range) ->
          ulhex.find('i').removeClass('selected')
          r = ulhex.find('i').slice(range[0], range[1])
          r.addClass('selected')

          ulascii.find('i').removeClass('selected')
          r = ulascii.find('i').slice(range[0], range[1])
          r.addClass('selected')

        dripcap.pubsub.sub 'PacketListView:select', (pkt) ->
          ulhex.empty()
          ulascii.empty()

          payload = pkt.payload

          hexhtml = ''
          asciihtml = ''

          for b in payload
            hexhtml += '<i>' + ("0" + b.toString(16)).slice(-2) + '</i>'

          for b in payload
            text =
              if 0x21 <= b <= 0x7e
                String.fromCharCode(b)
              else
                '.'
            asciihtml += '<i>' + text + '</i>'

          process.nextTick ->
            ulhex[0].innerHTML = hexhtml
            ulascii[0].innerHTML = asciihtml

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = BinaryView
