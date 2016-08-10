import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';

export default class PacketFilterView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      dripcap.package.load('main-view').then(pkg => {
        return $(() => {
          let m = $('<div/>');
          this.view = riot.mount(m[0], 'packet-filter-view')[0];
          return pkg.root.panel.leftSouthFixed(m);
        }
        );
      }
      );
      return res();
    }
    );
  }

  updateTheme(theme) {
    return this.comp.updateTheme(theme);
  }

  deactivate() {
    return dripcap.package.load('main-view').then(pkg => {
      pkg.root.panel.leftSouthFixed();
      this.view.unmount();
      return this.comp.destroy();
    }
    );
  }
}
