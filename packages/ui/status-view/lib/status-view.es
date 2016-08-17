import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';
import {
  Package,
  PubSub
} from 'dripcap';

export default class StatusView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return Package.load('main-view').then(pkg => {
        return $(() => {
          let m = $('<div/>');
          this.view = riot.mount(m[0], 'status-view')[0];
          pkg.root.panel.northFixed(m);

          PubSub.sub('core:capturing-status', stat => {
            this.view.capturing = stat.capturing;
            return this.view.update();
          });

          PubSub.sub('core:capturing-settings', data => {
            this.view.settings = data;
            return this.view.update();
          });

          return res();
        });
      });
    });
  }

  deactivate() {
    return Package.load('main-view').then(pkg => {
      pkg.root.panel.northFixed();
      this.view.unmount();
      return this.comp.destroy();
    });
  }
}
