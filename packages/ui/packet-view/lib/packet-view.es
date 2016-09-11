import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  remote
} from 'electron';
let {
  MenuItem
} = remote;
let {
  dialog
} = remote;
import fs from 'fs';
import {
  clipboard
} from 'electron';
import notifier from 'node-notifier';
import {
  Menu,
  Package,
  PubSub,
  Session
} from 'dripcap';

export default class PacketListView {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
    let pkg = await Package.load('main-view');

    let m = $('<div class="wrapper" />').attr('tabIndex', '0');
    pkg.root.panel.center('packet-view', m, $('<i class="fa fa-cubes"> Packet</i>'));
    this.view = riot.mount(m[0], 'packet-view')[0];

    Session.on('created', session => {
      this.view.set(null);
      this.view.update();
    });

    PubSub.sub('packet-list-view:select', pkt => {
      console.log(pkt)
      this.view.set(pkt);
      this.view.update();
    });

    this.copyMenu = function(menu, e) {
      let copy = () => remote.getCurrentWebContents().copy();
      menu.append(new MenuItem({
        label: 'Copy',
        click: copy,
        accelerator: 'CmdOrCtrl+C'
      }));
      return menu;
    };

    this.numValueMenu = function(menu, e) {
      let setBase = base => {
        return () => this.base = base;
      };

      menu.append(new MenuItem({
        label: 'Binary',
        type: 'radio',
        checked: (this.base === 2),
        click: setBase(2)
      }));
      menu.append(new MenuItem({
        label: 'Octal',
        type: 'radio',
        checked: (this.base === 8),
        click: setBase(8)
      }));
      menu.append(new MenuItem({
        label: 'Decimal',
        type: 'radio',
        checked: (this.base === 10),
        click: setBase(10)
      }));
      menu.append(new MenuItem({
        label: 'Hexadecimal',
        type: 'radio',
        checked: (this.base === 16),
        click: setBase(16)
      }));
      return menu;
    };

    this.layerMenu = function(menu, e) {
      let find = function(layer, ns) {
        if (layer.layers != null) {
          for (var k in layer.layers) {
            var v = layer.layers[k];
            if (k === ns) {
              return v;
            }
          }
          for (k in layer.layers) {
            var v = layer.layers[k];
            let r = find(v, ns);
            if (r != null) {
              return r;
            }
          }
        }
      };

      let exportRawData = () => {
        let layer = find(this.packet, this.clickedLayerNamespace);
        let filename = `${this.packet.interface}-${layer.name}-${this.packet.timestamp.toISOString()}.bin`;
        let path = dialog.showSaveDialog(remote.getCurrentWindow(), {
          defaultPath: filename
        });
        if (path != null) {
          fs.writeFileSync(path, layer.payload.apply(this.packet.payload));
        }
      };

      let exportPayload = () => {
        let layer = find(this.packet, this.clickedLayerNamespace);
        let filename = `${this.packet.interface}-${layer.name}-${this.packet.timestamp.toISOString()}.bin`;
        let path = dialog.showSaveDialog(remote.getCurrentWindow(), {
          defaultPath: filename
        });
        if (path != null) {
          fs.writeFileSync(path, layer.payload.apply(this.packet.payload));
        }
      };

      let copyAsJSON = () => {
        let layer = find(this.packet, this.clickedLayerNamespace);
        let json = JSON.stringify(layer, null, ' ');
        clipboard.writeText(json);
        return notifier.notify({
          title: 'Copied',
          message: json
        });
      };

      menu.append(new MenuItem({
        label: 'Export raw data',
        click: exportRawData
      }));
      menu.append(new MenuItem({
        label: 'Export payload',
        click: exportPayload
      }));
      menu.append(new MenuItem({
        type: 'separator'
      }));
      menu.append(new MenuItem({
        label: 'Copy Layer as JSON',
        click: copyAsJSON
      }));
      return menu;
    };

    Menu.register('packet-view:layer-menu', this.layerMenu);
    Menu.register('packet-view:layer-menu', this.copyMenu);
    Menu.register('packet-view:numeric-value-menu', this.numValueMenu);
    Menu.register('packet-view:numeric-value-menu', this.copyMenu);
    Menu.register('packet-view:context-menu', this.copyMenu);
  }

  async deactivate() {
    Menu.unregister('packet-view:layer-menu', this.layerMenu);
    Menu.unregister('packet-view:layer-menu', this.copyMenu);
    Menu.unregister('packet-view:numeric-value-menu', this.numValueMenu);
    Menu.unregister('packet-view:numeric-value-menu', this.copyMenu);
    Menu.unregister('packet-view:context-menu', this.copyMenu);

    let pkg = await Package.load('main-view');
    pkg.root.panel.center('packet-view');
    this.view.unmount();
    this.comp.destroy();
  }
}
