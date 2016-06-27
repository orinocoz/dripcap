<packet-view-custom-value>
  <script type="coffee">
    riot = require('riot')
    @on 'mount', =>
      if opts.tag?
        riot.mount(@root, opts.tag, value: opts.value)
  </script>
</packet-view-custom-value>

<packet-view-boolean-value>
  <i class="fa fa-check-square-o" if={ opts.value }></i>
  <i class="fa fa-square-o" if={ !opts.value }></i>
</packet-view-boolean-value>

<packet-view-integer-value>
  <i if={ base == 2 } oncontextmenu={ context }><i class="base">0b</i>{ opts.value.toString(2) }</i>
  <i if={ base == 8 } oncontextmenu={ context }><i class="base">0</i>{ opts.value.toString(8) }</i>
  <i if={ base == 10 } oncontextmenu={ context }>{ opts.value.toString(10) }</i>
  <i if={ base == 16 } oncontextmenu={ context }><i class="base">0x</i>{ opts.value.toString(16) }</i>
  <script type="coffee">
    remote = require('electron').remote
    @base = 10

    @context = (e) =>
      dripcap.menu.popup('packet-view:numeric-value-menu', @, remote.getCurrentWindow())
      e.stopPropagation()

  </script>
</packet-view-integer-value>

<packet-view-string-value>
  <i></i>
  <script type="coffee">
    $ = require('jquery')

    @on 'update', =>
      if @opts.value?
        @root.innerHTML = $('<div/>').text(@opts.value.toString()).html()
  </script>
</packet-view-string-value>

<packet-view-item>
  <li>
    <p class="label" onclick={ toggle } range={ opts.field.range.start + '-' + opts.field.range.end } oncontextmenu={ context } onmouseover={ fieldRange } onmouseout={ rangeOut }>
      <i class="fa fa-circle-o" show={ !opts.field.fields }></i>
      <i class="fa fa-arrow-circle-right" show={ opts.field.fields && !show }></i>
      <i class="fa fa-arrow-circle-down" show={ opts.field.fields && show }></i>
      <a class="name">{ opts.field.name }:</a>
      <packet-view-boolean-value if={ type == 'boolean' } value={ value }></packet-view-boolean-value>
      <packet-view-integer-value if={ type == 'integer' } value={ value }></packet-view-integer-value>
      <packet-view-string-value if={ type == 'string' } value={ value }></packet-view-string-value>
      <packet-view-custom-value if={ type == 'custom' } tag={ tag } value={ value }></packet-view-custom-value>
    </p>
    <ul show={ opts.field.fields && show }>
      <packet-view-item each={ f in opts.field.fields } layer={ opts.layer } field={ f }></packet-view-item>
    </ul>
  </li>

  <script type="coffee">
    remote = require('electron').remote
    @show = false

    @toggle = (e) =>
      @show = !@show if opts.field.fields?
      e.stopPropagation()

    @rangeOut = => @parent.rangeOut()

    @fieldRange = (e) =>
      @parent.fieldRange(e)

    @context = (e) =>
      if window.getSelection().toString().length > 0
        dripcap.menu.popup('packet-view:context-menu', @, remote.getCurrentWindow())
        e.stopPropagation()

    @on 'update', =>
      @layer = opts.layer

      @value =
        if opts.field.value?
          opts.field.value
        else
          @layer.attrs[opts.field.attr]

      @type =
        if opts.field.tag?
          @tag = opts.field.tag
          'custom'
        else if typeof @value == 'boolean'
          'boolean'
        else if Number.isInteger(@value)
          'integer'
        else if Buffer.isBuffer @value
          'buffer'
        else
          'string'

  </script>

  <style type="text/less">
    [riot-tag=packet-view-item] {
      -webkit-user-select: auto;
    }
  </style>

</packet-view-item>

<packet-view-layer>
  <p class="layer-name" oncontextmenu={ layerContext } onclick={ toggleLayer } onmouseover={ layerRange } onmouseout={ rangeOut }>
    <i class="fa fa-arrow-circle-right" show={ !visible }></i>
    <i class="fa fa-arrow-circle-down" show={ visible }></i>
    { layer.name }
    <i class="summary">{ layer.summary }</i>
  </p>
  <ul show={ visible }>
    <packet-view-item each={ f in layer.fields } layer={ layer } field={ f }></packet-view-item>
    <li if={ layer.error }>
      <a class="name">Error:</a> { layer.error }
    </li>
  </ul>
  <packet-view-layer each={ ns in rootKeys } layer={ rootLayers[ns] }></packet-view-layer>

  <script type="coffee">
    remote = require('electron').remote
    @visible = true

    @on 'update', =>
      @layer = opts.layer
      @rootKeys = []
      if @layer.layers?
        @rootLayers = @layer.layers
        @rootKeys = Object.keys @rootLayers

    @layerContext = (e) =>
      @clickedLayerNamespace = e.item.ns
      dripcap.menu.popup('packet-view:layer-menu', @, remote.getCurrentWindow())
      e.stopPropagation()

    @rangeOut = => @parent.rangeOut()

    @fieldRange = (e) => @parent.fieldRange(e)

    @layerRange = (e) => @parent.layerRange(e)

    @toggleLayer = (e) =>
      @visible = !@visible
      e.stopPropagation()

  </script>

</packet-view-layer>

<packet-view>

  <div if={ packet }>
    <ul>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Timestamp: </a><i>{ packet.timestamp }</i>
      </li>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Captured Length: </a><i>{ packet.caplen }</i>
      </li>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Actual Length: </a><i>{ packet.length }</i>
      </li>
      <li if={ packet.caplen < packet.length }>
        <i class="fa fa-exclamation-circle warn"> This packet has been truncated.</i>
      </li>
    </ul>
    <packet-view-layer each={ ns in rootKeys } layer={ rootLayers[ns] }></packet-view-layer>
  </div>

  <script type="coffee">
    remote = require('electron').remote

    @set = (pkt) =>
      @packet = pkt
      if pkt?
        @rootLayers = @packet.layers[Object.keys(@packet.layers)[0]].layers
        @rootKeys = Object.keys @rootLayers

    @fieldRange = (e) =>
      fieldRange = e.currentTarget.getAttribute('range').split '-'
      range = [parseInt(fieldRange[0]), parseInt(fieldRange[1])]
      dripcap.pubsub.pub 'packet-view:range', range

    @layerRange = (e) =>
      find = (layer, ns) ->
        if layer.layers?
          for k, v of layer.layers
            return layer if k == ns
          for k, v of layer.layers
            r = find(v, ns)
            return r if r?

      layer = find @packet, e.item.ns
      range = [layer.payload.start, layer.payload.end]
      dripcap.pubsub.pub 'packet-view:range', range

    @rangeOut = =>
      dripcap.pubsub.pub 'packet-view:range', [0, 0]

  </script>

  <style type="text/less">
    [riot-tag=packet-view] {
      -webkit-user-select: auto;

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

      .warn {
        color: @error;
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

    [riot-tag=binary-view] {
      i.selected {
        background-color: @highlight;
      }
    }

  </style>

</packet-view>
