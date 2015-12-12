import $ from 'jquery'
import riot from 'riot'
import { Component, Panel } from 'dripper/component'

export default class BinaryView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
    dripcap.package.load('main-view').then((pkg) => {
      $(() => {

        let m = $('<div class="wrapper" />').attr('tabIndex', '0')
        pkg.root.panel.bottom('binary-view', m, $('<i class="fa fa-file-text"> Binary</i>'))

        this.view = riot.mount(m[0], 'binary-view')[0]
        let ulhex = $(this.view.root).find('.hex')
        let ulascii = $(this.view.root).find('.ascii')

        dripcap.session.on('created', (session) => {
          ulhex.empty()
          ulascii.empty()
        });

        dripcap.pubsub.sub('PacketView:range', (range) => {
          ulhex.find('i').removeClass('selected')
          let r = ulhex.find('i').slice(range[0], range[1])
          r.addClass('selected')

          ulascii.find('i').removeClass('selected')
          r = ulascii.find('i').slice(range[0], range[1])
          r.addClass('selected')
        })

        dripcap.pubsub.sub('PacketListView:select', (pkt) => {
          ulhex.empty()
          ulascii.empty()

          let payload = pkt.payload

          let hexhtml = ''
          let asciihtml = ''

          for (let b of payload) {
            hexhtml += '<i>' + ("0" + b.toString(16)).slice(-2) + '</i>'
          }

          for (let b of payload) {
            let text = '.'
            if (0x21 <= b && b <= 0x7e) {
              text = String.fromCharCode(b)
            }
            asciihtml += '<i>' + text + '</i>'
          }

          process.nextTick(() => {
            ulhex[0].innerHTML = hexhtml
            ulascii[0].innerHTML = asciihtml
          })
        })
      })
    })
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.package.load('main-view').then((pkg) => {
      pkg.root.panel.bottom('binary-view')
      this.view.unmount()
      this.comp.destroy()
    })
  }
}
