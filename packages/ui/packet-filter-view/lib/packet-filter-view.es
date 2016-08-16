import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  Package
} from 'dripcap';

export default class PacketFilterView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      Package.load('main-view').then(pkg => {
        return $(() => {
          let m = $('<div/>');
          this.view = riot.mount(m[0], 'packet-filter-view')[0];
          return pkg.root.panel.leftSouthFixed(m);
        });
      });
      return res();
    });
  }

  deactivate() {
    return Package.load('main-view').then(pkg => {
      pkg.root.panel.leftSouthFixed();
      this.view.unmount();
      return this.comp.destroy();
    });
  }
}
