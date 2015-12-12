import $ from 'jquery'
import riot from 'riot'
import {Component} from 'dripper/component'
import remote from 'remote'
import fs from 'fs'
import {clipboard} from 'electron'
const MenuItem = remote.require('menu-item')
const dialog = remote.require('dialog')

export default class PacketListView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)

    dripcap.package.load('main-view').then((pkg) => {
      $(() => {
        let m = $('<div class="wrapper" />').attr('tabIndex', '0')
        pkg.root.panel.center('packet-view', m, $('<i class="fa fa-cubes"> Packet</i>'))
        this.view = riot.mount(m[0], 'packet-view')[0]

        dripcap.session.on('created', (session) => {
          this.view.set(null)
          this.view.update()
        })

        dripcap.pubsub.sub('PacketListView:select',(pkt) => {
          this.view.set(pkt)
          this.view.update()
        })
      })
    })

    this.copyMenu = (menu, e) => {
      let copy = () => remote.getCurrentWebContents().copy()
      menu.append(new MenuItem({label: 'Copy', click: copy, accelerator: 'CmdOrCtrl+C'}))
      return menu
    }

    this.numValueMenu = (menu, e) => {
      let setBase = (base) => {
        return () => this.base = base
      }
      menu.append(new MenuItem({label: 'Binary', type: 'radio', checked: (this.base == 2), click: setBase(2)}))
      menu.append(new MenuItem({label: 'Octal', type: 'radio', checked: (this.base == 8), click: setBase(8)}))
      menu.append(new MenuItem({label: 'Decimal', type: 'radio', checked: (this.base == 10), click: setBase(10)}))
      menu.append(new MenuItem({label: 'Hexadecimal', type: 'radio', checked: (this.base == 16), click: setBase(16)}))
      return menu
    }

    this.layerMenu = function(menu, e) {
      let exportRawData = () => {
        let packet = this.packet
        let index = Math.max(this.clickedLayerIndex - 1, 0)
        let layer = packet.layers[index]
        let filename = `${packet.interface}-${layer.name}-${packet.timestamp.toISOString()}.bin`
        let path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
        if (path != null) {
          fs.writeFileSync(path, layer.payload.apply(packet.payload))
        }
      }

      let exportPayload = () => {
        let packet = this.packet
        let layer = packet.layers[this.clickedLayerIndex]
        let filename = `${packet.interface}-${layer.name}-${packet.timestamp.toISOString()}.bin`
        let path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
        if (path != null) {
          fs.writeFileSync(path, layer.payload.apply(packet.payload))
        }
      }

      let copyAsJSON = () => {
        let packet = this.packet
        let layer = packet.layers[this.clickedLayerIndex]
        clipboard.writeText(JSON.stringify(layer, null, ' '))
      }

      menu.append(new MenuItem({label: 'Export raw data', click: exportRawData}))
      menu.append(new MenuItem({label: 'Export payload', click: exportPayload}))
      menu.append(new MenuItem({type: 'separator'}))
      menu.append(new MenuItem({label: 'Copy Layer as JSON', click: copyAsJSON}))
      return menu
    }

    dripcap.menu.register('packetView: LayerMenu', this.layerMenu)
    dripcap.menu.register('packetView: LayerMenu', this.copyMenu)
    dripcap.menu.register('packetView: NumericValueMenu', this.numValueMenu)
    dripcap.menu.register('packetView: NumericValueMenu', this.copyMenu)
    dripcap.menu.register('packetView: ContextMenu', this.copyMenu)
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.menu.unregister('packetView: LayerMenu', this.layerMenu)
    dripcap.menu.unregister('packetView: LayerMenu', this.copyMenu)
    dripcap.menu.unregister('packetView: NumericValueMenu', this.numValueMenu)
    dripcap.menu.unregister('packetView: NumericValueMenu', this.copyMenu)
    dripcap.menu.unregister('packetView: ContextMenu', this.copyMenu)

    dripcap.package.load('main-view').then((pkg) => {
      pkg.root.panel.center('packet-view')
      this.view.unmount()
      this.comp.destroy()
    })
  }
}
