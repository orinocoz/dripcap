$ = require('jquery')
riot = require('riot')
{Component} = require('dripcap/component')
remote = require('remote')
MenuItem = remote.require('menu-item')
dialog = remote.require('dialog')
fs = require('fs')
clipboard = require('clipboard')

class PacketListView

  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        $ =>
          m = $('<div class="wrapper" />').attr 'tabIndex', '0'
          pkg.root.panel.center('packet-view', m, $('<i class="fa fa-cubes"> Packet</i>'))
          @view = riot.mount(m[0], 'packet-view')[0]

          dripcap.session.on 'created', (session) =>
            @view.set(null)
            @view.update()

          dripcap.pubsub.sub 'packet-list-view:select', (pkt) =>
            @view.set(pkt)
            @view.update()

          res()

      @copyMenu = (menu, e) ->
        copy = ->
          remote.getCurrentWebContents().copy()
        menu.append(new MenuItem(label: 'Copy', click: copy, accelerator: 'CmdOrCtrl+C'))
        menu

      @numValueMenu = (menu, e) ->
        setBase = (base) =>
          => @base = base

        menu.append(new MenuItem(label: 'Binary', type: 'radio', checked: (@base == 2), click: setBase(2)))
        menu.append(new MenuItem(label: 'Octal', type: 'radio', checked: (@base == 8), click: setBase(8)))
        menu.append(new MenuItem(label: 'Decimal', type: 'radio', checked: (@base == 10), click: setBase(10)))
        menu.append(new MenuItem(label: 'Hexadecimal', type: 'radio', checked: (@base == 16), click: setBase(16)))
        menu

      @layerMenu = (menu, e) ->
        find = (layer, ns) ->
          if layer.layers?
            for k, v of layer.layers
              return v if k == ns
            for k, v of layer.layers
              r = find(v, ns)
              return r if r?

        exportRawData = =>
          layer = find @packet, @clickedLayerNamespace
          filename = "#{@packet.interface}-#{layer.name}-#{@packet.timestamp.toISOString()}.bin"
          path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
          if path?
            fs.writeFileSync path, layer.payload.apply @packet.payload

        exportPayload = =>
          layer = find @packet, @clickedLayerNamespace
          filename = "#{@packet.interface}-#{layer.name}-#{@packet.timestamp.toISOString()}.bin"
          path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
          if path?
            fs.writeFileSync path, layer.payload.apply @packet.payload

        copyAsJSON = =>
          layer = find @packet, @clickedLayerNamespace
          clipboard.writeText JSON.stringify(layer, null, ' ')

        menu.append(new MenuItem(label: 'Export raw data', click: exportRawData))
        menu.append(new MenuItem(label: 'Export payload', click: exportPayload))
        menu.append(new MenuItem(type: 'separator'))
        menu.append(new MenuItem(label: 'Copy Layer as JSON', click: copyAsJSON))
        menu

      dripcap.menu.register 'packet-view:layer-menu', @layerMenu
      dripcap.menu.register 'packet-view:layer-menu', @copyMenu
      dripcap.menu.register 'packet-view:numeric-value-menu', @numValueMenu
      dripcap.menu.register 'packet-view:numeric-value-menu', @copyMenu
      dripcap.menu.register 'packet-view:context-menu', @copyMenu

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.menu.unregister 'packet-view:layer-menu', @layerMenu
    dripcap.menu.unregister 'packet-view:layer-menu', @copyMenu
    dripcap.menu.unregister 'packet-view:numeric-value-menu', @numValueMenu
    dripcap.menu.unregister 'packet-view:numeric-value-menu', @copyMenu
    dripcap.menu.unregister 'packet-view:context-menu', @copyMenu

    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.center('packet-view')
      @view.unmount()
      @comp.destroy()

module.exports = PacketListView
