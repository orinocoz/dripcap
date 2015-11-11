<packet-view-boolean-value>
  <i class="fa fa-check-square-o" if={ opts.value }></i>
  <i class="fa fa-square-o" if={ !opts.value }></i>
</packet-view-boolean-value>

<packet-view-integer-value>
  <i if={ base == 2 } oncontextmenu={ context }><i class="base">0b</i>{ opts.value.toString(2) }</i>
  <i if={ base == 8 } oncontextmenu={ context }><i class="base">0</i>{ opts.value.toString(8) }</i>
  <i if={ base == 10 } oncontextmenu={ context }>{ opts.value.toString(10) }</i>
  <i if={ base == 16 } oncontextmenu={ context }><i class="base">0x</i>{ opts.value.toString(16) }</i>
  <script type="text/coffeescript">
    remote = require('remote')
    Menu = remote.require('menu')
    MenuItem = remote.require('menu-item')

    @base = 10

    setBase = (base) =>
      => @base = base

    @context = =>
      menu = new Menu()
      menu.append(new MenuItem(label: 'Binary', type: 'radio', checked: (@base == 2), click: setBase(2)))
      menu.append(new MenuItem(label: 'Octal', type: 'radio', checked: (@base == 8), click: setBase(8)))
      menu.append(new MenuItem(label: 'Decimal', type: 'radio', checked: (@base == 10), click: setBase(10)))
      menu.append(new MenuItem(label: 'Hexadecimal', type: 'radio', checked: (@base == 16), click: setBase(16)))
      menu.popup(remote.getCurrentWindow())

  </script>
</packet-view-integer-value>

<packet-view-string-value>
  <i></i>
  <script type="text/coffeescript">
    @on 'update', =>
      if @opts.value?
        @root.innerHTML = $('<div/>').text(@opts.value.toString()).html()
  </script>
</packet-view-string-value>

<packet-view-item>
  <li>
    <p class="label" onclick={ toggle } range={ opts.field.range.start + '-' + opts.field.range.end } onmouseover={ fieldRange } onmouseout={ rangeOut }>
      <i class="fa fa-circle-o" show={ !opts.field.fields }></i>
      <i class="fa fa-arrow-circle-right" show={ opts.field.fields && !show }></i>
      <i class="fa fa-arrow-circle-down" show={ opts.field.fields && show }></i>
      <a class="name">{ opts.field.name }:</a>
      <packet-view-boolean-value if={ type == 'boolean' } value={ value }></packet-view-boolean-value>
      <packet-view-integer-value if={ type == 'integer' } value={ value }></packet-view-integer-value>
      <packet-view-string-value if={ type == 'string' } value={ value }></packet-view-string-value>
    </p>
    <ul show={ opts.field.fields && show }>
      <packet-view-item each={ f in opts.field.fields } layer={ opts.layer } field={ f }></packet-view-item>
    </ul>
  </li>

  <script type="text/coffeescript">
    @show = false

    @toggle = (e) =>
      @show = !@show if opts.field.fields?
      e.stopPropagation()

    @rangeOut = => @parent.rangeOut()

    @fieldRange = (e) =>
      @parent.fieldRange(e)

    @on 'update', =>
      @layer = @parent.layer

      @value =
        if opts.field.value?
          opts.field.value
        else
          @layer.attrs[opts.field.attr]

      @type =
        if typeof @value == 'boolean'
          'boolean'
        else if Number.isInteger(@value)
          'integer'
        else if Buffer.isBuffer @value
          'buffer'
        else
          'string'

  </script>

</packet-view-item>

<packet-view>

  <div if={ packet }>
    <ul>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Timestamp: </a><i>{ packet.timestamp }</i>
      </li>
    </ul>
    <div each={ layer, i in packet.layers } if={ i > 0 } onclick={ toggleLayer }>
      <p class="layer-name" oncontextmenu={ layerContext } onmouseover={ layerRange } onmouseout={ rangeOut }>
        <i class="fa fa-arrow-circle-right" show={ !layers[i] }></i>
        <i class="fa fa-arrow-circle-down" show={ layers[i] }></i>
        { layer.name }
        <i class="summary">{ layer.summary }</i>
      </p>
      <ul show={ layers[i] }>
        <packet-view-item each={ f in layer.fields } layer={ layer } field={ f }></packet-view-item>
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

    menu = new Menu()
    menu.append(new MenuItem(label: 'Export raw data', click: exportRawData))
    menu.append(new MenuItem(label: 'Export payload', click: exportPayload))
    menu.append(new MenuItem(type: 'separator'))
    menu.append(new MenuItem(label: 'Copy as JSON', click: copyAsJSON))

    @layerContext = (e) =>
      @clickedLayerIndex = e.item.i
      menu.popup(remote.getCurrentWindow())

    @set = (pkt) =>
      @packet = pkt
      @layers = []
      if pkt?
        for i in pkt.layers
          @layers.push false
        @layers[@layers.length - 1] = true

    @toggleLayer = (e) =>
      index = e.item.i
      @layers[index] = !@layers[index]
      e.stopPropagation()

    @fieldRange = (e) =>
      fieldRange = e.currentTarget.getAttribute('range').split '-'
      range = [parseInt(fieldRange[0]), parseInt(fieldRange[1])]
      dripcap.pubsub.pub 'PacketView:range', range, 1

    @layerRange = (e) =>
      max = Math.max(e.item.i - 1, 0)
      layer = @packet.layers[max]
      range = [layer.payload.start, layer.payload.end]
      dripcap.pubsub.pub 'PacketView:range', range, 1

    @rangeOut = =>
      dripcap.pubsub.pub 'PacketView:range', [0, 0], 1

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

      i.base {
        font-weight: bold;
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
