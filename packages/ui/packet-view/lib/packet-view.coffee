$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')
remote = require('remote')
MenuItem = remote.require('menu-item')
dialog = remote.require('dialog')
fs = require('fs')
clipboard = require('clipboard')

class PacketListView

  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('main-view').then (pkg) =>
      $ =>
        m = $('<div class="wrapper" />').attr 'tabIndex', '0'
        pkg.root.panel.center('packet-view', m, $('<i class="fa fa-cubes"> Packet</i>'))
        @view = riot.mount(m[0], 'packet-view')[0]

        dripcap.session.on 'created', (session) =>
          @view.set(null)
          @view.update()

        dripcap.pubsub.sub 'PacketListView:select', (pkt) =>
          @view.set(pkt)
          @view.update()

    @numValueMenu  = (menu, e) ->
      setBase = (base) =>
        => @base = base

      menu.append(new MenuItem(label: 'Binary', type: 'radio', checked: (@base == 2), click: setBase(2)))
      menu.append(new MenuItem(label: 'Octal', type: 'radio', checked: (@base == 8), click: setBase(8)))
      menu.append(new MenuItem(label: 'Decimal', type: 'radio', checked: (@base == 10), click: setBase(10)))
      menu.append(new MenuItem(label: 'Hexadecimal', type: 'radio', checked: (@base == 16), click: setBase(16)))
      menu

    @layerMenu = (menu, e) ->
      exportRawData = =>
        index = Math.max @clickedLayerIndex - 1, 0
        layer = @packet.layers[index]
        filename = "#{@packet.interface}-#{layer.name}-#{@packet.timestamp.toISOString()}.bin"
        path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
        if path?
          fs.writeFileSync path, layer.payload.apply @packet.payload

      exportPayload = =>
        layer = @packet.layers[@clickedLayerIndex]
        filename = "#{@packet.interface}-#{layer.name}-#{@packet.timestamp.toISOString()}.bin"
        path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
        if path?
          fs.writeFileSync path, layer.payload.apply @packet.payload

      copyAsJSON = =>
        layer = @packet.layers[@clickedLayerIndex]
        clipboard.writeText JSON.stringify(layer, null, ' ')

      menu.append(new MenuItem(label: 'Export raw data', click: exportRawData))
      menu.append(new MenuItem(label: 'Export payload', click: exportPayload))
      menu.append(new MenuItem(type: 'separator'))
      menu.append(new MenuItem(label: 'Copy as JSON', click: copyAsJSON))
      menu

    dripcap.menu.register 'packetView: LayerMenu', @layerMenu
    dripcap.menu.register 'packetView: NumericValueMenu', @numValueMenu

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.menu.unregister 'packetView: LayerMenu', @layerMenu
    dripcap.menu.unregister 'packetView: NumericValueMenu', @numValueMenu

    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.center('packet-view')
      @view.unmount()
      @comp.destroy()

module.exports = PacketListView
