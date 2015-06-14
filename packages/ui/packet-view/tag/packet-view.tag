<packet-view-value>
  <i></i>

  <script type="text/coffeescript">
    @on 'mount update', =>
      return unless @opts.packet?

      value =
        if @opts.field.value?
          @opts.field.value
        else if @opts.packet?
          @opts.packet.layers[@opts['layer-index']].attrs[@opts.field.attr]

      @root.innerHTML =
        if typeof value == 'boolean'
          if value
            '<i class="fa fa-check-square-o"></i>'
          else
            '<i class="fa fa-square-o"></i>'
        else if Buffer.isBuffer value
          str = ""
          for b in value.slice(0, 8)
            str += ("0" + b.toString(16)).slice(-2) + " "
          str += '... ' if value.length > 8
          str + "(#{value.length} bytes)"
        else if !value?
          ''
        else
          $('<div/>').text(value.toString()).html()
  </script>
</packet-view-value>

<packet-view-item>
  <li>
    <p class="label" onclick={ toggle } range={ opts.field.range.start + '-' + opts.field.range.end } onmouseover={ fieldRange } onmouseout={ rangeOut }>
      <i class="fa fa-circle-o" show={ !opts.field.fields }></i>
      <i class="fa fa-arrow-circle-right" show={ opts.field.fields && !show }></i>
      <i class="fa fa-arrow-circle-down" show={ opts.field.fields && show }></i>
      <a class="name">{ opts.field.name }:</a> <packet-view-value packet={ opts.packet } layer-index={ opts['layer-index'] } field={ opts.field }></packet-view-value> { opts.field.note }
    </p>

    <ul show={ opts.field.fields && show }>
      <packet-view-item each={ f in opts.field.fields } packet={ parent.opts.packet } layer-index={ parent.opts['layer-index'] } field={ f }></packet-view-item>
    </ul>
  </li>

  <script type="text/coffeescript">
    @show = false

    @toggle = =>
      @show = !@show

    @rangeOut = => @parent.rangeOut()

    @fieldRange = (e) =>
      index = opts['layer-index']
      @parent.fieldRange(e, index)

  </script>
</packet-view-item>

<packet-view>

  <div if={ packet }>
    <ul>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Timestamp: </a><i>{ packet.timestamp }</i>
      </li>
    </ul>
    <div each={ layer, i in packet.layers } if={ i > 0 }>
      <p class="layer-name" layer-index={ i } oncontextmenu={ layerContext } onclick={ toggleLayer } onmouseover={ layerRange } onmouseout={ rangeOut }>
        <i class="fa fa-arrow-circle-right" show={ !layers[i] }></i>
        <i class="fa fa-arrow-circle-down" show={ layers[i] }></i>
        { layer.name }
        <i class="summary">{ layer.summary }</i>
      </p>
      <ul show={ layers[i] }>
        <packet-view-item each={ f in layer.fields } layer-index={ i } packet={ packet } field={ f }></packet-view-item>
        <li if={ layer.error }>
          <a class="name">Error:</a> { layer.error }
        </li>
      </ul>
    </div>
  </div>

  <script type="text/coffeescript">
    remote = require('remote')
    Menu = remote.require('menu')
    MenuItem = remote.require('menu-item')
    dialog = remote.require('dialog')
    fs = require('fs')
    clipboard = require('clipboard')

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

    @menu = new Menu()
    @menu.append(new MenuItem(label: 'Export raw data', click: exportRawData))
    @menu.append(new MenuItem(label: 'Export payload', click: exportPayload))
    @menu.append(new MenuItem(type: 'separator'))
    @menu.append(new MenuItem(label: 'Copy as JSON', click: copyAsJSON))

    @set = (pkt) =>
      @packet = pkt
      @layers = []
      if pkt?
        for i in pkt.layers
          @layers.push false
        @layers[@layers.length - 1] = true

    @layerContext = (e) =>
      @clickedLayerIndex = parseInt e.currentTarget.getAttribute('layer-index')
      @menu.popup(remote.getCurrentWindow())

    @toggleLayer = (e) =>
      index = parseInt e.currentTarget.getAttribute('layer-index')
      @layers[index] = !@layers[index]

    @rangeOut = =>
      dripcap.pubsub.pub 'PacketView:range', [0, 0], 1

    layerRange = ->


    @fieldRange = (e, index) =>
      fieldRange = e.currentTarget.getAttribute('range').split '-'
      range = [parseInt(fieldRange[0]), parseInt(fieldRange[1])]
      dripcap.pubsub.pub 'PacketView:range', range, 1

    @layerRange = (e) =>
      max = Math.max(e.currentTarget.getAttribute('layer-index') - 1, 0)
      layer = @packet.layers[max]
      range = [layer.payload.start, layer.payload.end]
      dripcap.pubsub.pub 'PacketView:range', range, 1

  </script>

  <style type="text/less">
    [riot-tag=packet-view] {
      table {
        width: 100%;
        align-self: stretch;
        border-spacing: 0px;
        padding: 10px;

        td {
          cursor: default;
        }
      }

      .name {
        color: @label;
        cursor: default;
      }


      .layer-name {
        white-space: nowrap;
        cursor: default;
        margin-left: 10px;
      }

      .summary {
        padding-left: 10px;
        color: @summary;
      }

      ul {
        padding-left: 20px;
      }

      li {
        white-space: nowrap;
        list-style: none;
      }

      i {
        font-style: normal;
      }

      .label {
        margin: 0px;
      }

      .fa-circle-o {
        opacity: 0.1;
      }

      .layer-name:hover, .label:hover {
        background-color: fade(@highlight, 40%);
      }
    }

  </style>

</packet-view>
