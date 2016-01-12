$ = require('jquery')
riot = require('riot')
Component = require('dripcap/component')
Panel = require('dripcap/panel')

class BinaryView

  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        $ =>
          m = $('<div class="wrapper" />').attr 'tabIndex', '0'
          pkg.root.panel.bottom('binary-view', m, $('<i class="fa fa-file-text"> Binary</i>'))

          @view = riot.mount(m[0], 'binary-view')[0]
          ulhex = $(@view.root).find('.hex')
          ulascii = $(@view.root).find('.ascii')

          dripcap.session.on 'created', (session) ->
            ulhex.empty()
            ulascii.empty()

          dripcap.pubsub.sub 'packet-view:range', (range) ->
            ulhex.find('i').removeClass('selected')
            r = ulhex.find('i').slice(range[0], range[1])
            r.addClass('selected')

            ulascii.find('i').removeClass('selected')
            r = ulascii.find('i').slice(range[0], range[1])
            r.addClass('selected')

          dripcap.pubsub.sub 'packet-list-view:select', (pkt) ->
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

          res()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.bottom('binary-view')
      @view.unmount()
      @comp.destroy()

module.exports = BinaryView
