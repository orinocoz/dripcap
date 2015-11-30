<packet-view-boolean-value>
  <i class="fa fa-check-square-o" if={ opts.value }></i>
  <i class="fa fa-square-o" if={ !opts.value }></i>
</packet-view-boolean-value>

<packet-view-integer-value>
  <i if={ base == 2 } oncontextmenu={ context }><i class="base">0b</i>{ opts.value.toString(2) }</i>
  <i if={ base == 8 } oncontextmenu={ context }><i class="base">0</i>{ opts.value.toString(8) }</i>
  <i if={ base == 10 } oncontextmenu={ context }>{ opts.value.toString(10) }</i>
  <i if={ base == 16 } oncontextmenu={ context }><i class="base">0x</i>{ opts.value.toString(16) }</i>
  <script type="es6">
    import remote from 'remote'
    this.base = 10
    this.context = () => dripcap.menu.popup('packetView: NumericValueMenu', this, remote.getCurrentWindow())
  </script>
</packet-view-integer-value>

<packet-view-string-value>
  <i></i>
  <script type="es6">
    this.on('update', () => {
      if (this.opts.value != null) {
        this.root.innerHTML = $('<div/>').text(this.opts.value.toString()).html()
      }
    })
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
    </p>
    <ul show={ opts.field.fields && show }>
      <packet-view-item each={ f in opts.field.fields } layer={ opts.layer } field={ f }></packet-view-item>
    </ul>
  </li>

  <script type="es6">
  import remote from 'remote'
  this.show = false

  this.toggle = (e) => {
    if (this.opts.field.fields != null) {
      this.show = !this.show
    }
    e.stopPropagation()
  }

  this.rangeOut = () => this.parent.rangeOut()

  this.fieldRange = (e) => this.parent.fieldRange(e)

  this.context = () => {
    if (window.getSelection().toString().length > 0) {
      dripcap.menu.popup('packetView: ContextMenu', this, remote.getCurrentWindow())
    }
  }

  this.on('update', () => {
    this.layer = this.parent.layer
    if (opts.field.value != null) {
      this.value = opts.field.value
    } else {
      this.value = this.layer.attrs[opts.field.attr]
    }

    if (typeof this.value == 'boolean') {
      this.type = 'boolean'
    } else if (Number.isInteger(this.value)) {
      this.type = 'integer'
    } else if (Buffer.isBuffer(this.value)) {
      this.type = 'buffer'
    } else {
      this.type = 'string'
    }
  })
  </script>

  <style type="text/less">
    [riot-tag=packet-view-item] {
      -webkit-user-select: auto;
    }
  </style>

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

  <script type="es6">
  import remote from 'remote'

  this.layerContext = (e) => {
    this.clickedLayerIndex = e.item.i
    dripcap.menu.popup('packetView: LayerMenu', this, remote.getCurrentWindow())
  }

  this.set = (pkt) => {
    this.packet = pkt
    this.layers = []
    if (pkt != null) {
      for (let i of pkt.layers) {
        this.layers.push(false)
      }
      this.layers[this.layers.length - 1] = true
    }
  }

  this.toggleLayer = (e) => {
    let index = e.item.i
    this.layers[index] = !this.layers[index]
    e.stopPropagation()
  }

  this.fieldRange = (e) => {
    let fieldRange = e.currentTarget.getAttribute('range').split('-')
    let range = [parseInt(fieldRange[0]), parseInt(fieldRange[1])]
    dripcap.pubsub.pub('PacketView:range', range)
  }

  this.layerRange = (e) => {
    let max = Math.max(e.item.i - 1, 0)
    let layer = this.packet.layers[max]
    let range = [layer.payload.start, layer.payload.end]
    dripcap.pubsub.pub('PacketView:range', range)
  }

  this.rangeOut = () => dripcap.pubsub.pub('PacketView:range', [0, 0])

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
