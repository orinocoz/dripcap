<packet-view-custom-value>
  <script type="babel">
  import riot from 'riot';
  this.on('mount', () => {
    if (opts.tag != null) {
      return riot.mount(this.root, opts.tag, {value: opts.value});
    }
  });
  </script>
</packet-view-custom-value>

<packet-view-boolean-value>
  <i class="fa fa-check-square-o" if={ opts.value }></i>
  <i class="fa fa-square-o" if={ !opts.value }></i>
</packet-view-boolean-value>

<packet-view-buffer-value>
  <i>{ opts.value.length } bytes</i>
</packet-view-buffer-value>

<packet-view-integer-value>
  <i if={ base == 2 } oncontextmenu={ context }><i class="base">0b</i>{ opts.value.toString(2) }</i>
  <i if={ base == 8 } oncontextmenu={ context }><i class="base">0</i>{ opts.value.toString(8) }</i>
  <i if={ base == 10 } oncontextmenu={ context }>{ opts.value.toString(10) }</i>
  <i if={ base == 16 } oncontextmenu={ context }><i class="base">0x</i>{ opts.value.toString(16) }</i>
  <script type="babel">
  import { remote } from 'electron';
  this.base = 10;

  this.context = e => {
    dripcap.menu.popup('packet-view:numeric-value-menu', this, remote.getCurrentWindow());
    return e.stopPropagation();
  };
  </script>
</packet-view-integer-value>

<packet-view-string-value>
  <i></i>
  <script type="babel">
  import $ from 'jquery';

  this.on('update', () => {
    if (this.opts.value != null) {
      return this.root.innerHTML = $('<div/>').text(this.opts.value.toString()).html();
    }
  });
  </script>
</packet-view-string-value>

<packet-view-item>
  <li>
    <p class="label" onclick={ toggle } range={ opts.field.data.start + '-' + opts.field.data.end } oncontextmenu={ context } onmouseover={ fieldRange } onmouseout={ rangeOut }>
      <i class="fa fa-circle-o" show={ !opts.field.fields }></i>
      <i class="fa fa-arrow-circle-right" show={ opts.field.fields && !show }></i>
      <i class="fa fa-arrow-circle-down" show={ opts.field.fields && show }></i>
      <a class="name">{ opts.field.name }:</a>
      <packet-view-boolean-value if={ type == 'boolean' } value={ value }></packet-view-boolean-value>
      <packet-view-integer-value if={ type == 'integer' } value={ value }></packet-view-integer-value>
      <packet-view-string-value if={ type == 'string' } value={ value }></packet-view-string-value>
      <packet-view-buffer-value if={ type == 'buffer' } value={ value }></packet-view-buffer-value>
      <packet-view-custom-value if={ type == 'custom' } tag={ tag } value={ value }></packet-view-custom-value>
    </p>
    <ul show={ opts.field.fields && show }>
      <packet-view-item each={ f in opts.field.fields } layer={ opts.layer } field={ f }></packet-view-item>
    </ul>
  </li>

  <script type="babel">
  import { remote } from 'electron';
  this.show = false;

  this.toggle = e => {
    if (opts.field.fields != null) { this.show = !this.show; }
    return e.stopPropagation();
  };

  this.rangeOut = () => this.parent.rangeOut();

  this.fieldRange = e => {
    return this.parent.fieldRange(e);
  };

  this.context = e => {
    if (window.getSelection().toString().length > 0) {
      dripcap.menu.popup('packet-view:context-menu', this, remote.getCurrentWindow());
      return e.stopPropagation();
    }
  };

  this.on('update', () => {
    this.layer = opts.layer;

    this.value =
      (opts.field.value != null) ?
        opts.field.value
      :
        this.layer.attrs[opts.field.attr];

    return this.type =
      (opts.field.tag != null) ?
        (this.tag = opts.field.tag,
        'custom')
      : typeof this.value === 'boolean' ?
        'boolean'
      : Number.isInteger(this.value) ?
        'integer'
      : Buffer.isBuffer(this.value) ?
        'buffer'
      :
        'string';
  }
  );
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

  <script type="babel">
  import { remote } from 'electron';
  this.visible = true;

  this.on('update', () => {
    this.layer = opts.layer;
    this.rootKeys = [];
    if (this.layer.layers != null) {
      this.rootLayers = this.layer.layers;
      return this.rootKeys = Object.keys(this.rootLayers);
    }
  }
  );

  this.layerContext = e => {
    this.clickedLayerNamespace = e.item.ns;
    dripcap.menu.popup('packet-view:layer-menu', this, remote.getCurrentWindow());
    return e.stopPropagation();
  };

  this.rangeOut = () => this.parent.rangeOut();

  this.fieldRange = e => this.parent.fieldRange(e);

  this.layerRange = e => this.parent.layerRange(e);

  this.toggleLayer = e => {
    this.visible = !this.visible;
    return e.stopPropagation();
  };
  </script>

</packet-view-layer>

<packet-view>

  <div if={ packet }>
    <ul>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Timestamp: </a><i>{ packet.timestamp }</i>
      </li>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Captured Length: </a><i>{ packet.payload.length }</i>
      </li>
      <li>
        <i class="fa fa-circle-o"></i><a class="name"> Actual Length: </a><i>{ packet.len }</i>
      </li>
      <li if={ packet.caplen < packet.length }>
        <i class="fa fa-exclamation-circle warn"> This packet has been truncated.</i>
      </li>
    </ul>
    <packet-view-layer each={ ns in rootKeys } layer={ rootLayers[ns] }></packet-view-layer>
  </div>

  <script type="babel">
  import { remote } from 'electron';

  this.set = pkt => {
    this.packet = pkt;
    if (pkt != null) {
      this.rootLayers = this.packet.layers;
      return this.rootKeys = Object.keys(this.rootLayers);
    }
  };

  this.fieldRange = e => {
    let fieldRange = e.currentTarget.getAttribute('range').split('-');
    let range = [parseInt(fieldRange[0]), parseInt(fieldRange[1])];
    return dripcap.pubsub.pub('packet-view:range', range);
  };

  this.layerRange = e => {
    let find = function(layer, ns) {
      if (layer.layers != null) {
        for (var k in layer.layers) {
          var v = layer.layers[k];
          if (k === ns) { return layer; }
        }
        for (k in layer.layers) {
          var v = layer.layers[k];
          let r = find(v, ns);
          if (r != null) { return r; }
        }
      }
    };

    let layer = find(this.packet, e.item.ns);
    let range = [layer.payload.start, layer.payload.end];
    return dripcap.pubsub.pub('packet-view:range', range);
  };

  this.rangeOut = () => {
    return dripcap.pubsub.pub('packet-view:range', [0, 0]);
  };
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
