import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';
import {
  Package,
  PubSub
} from 'dripcap';

export default class StatusView {
  async activate() {
    let pkg = await Package.load('main-view');
    this.comp = new Component(`${__dirname}/../tag/*.tag`);

    let m = $('<div/>');
    this.view = riot.mount(m[0], 'status-view')[0];
    pkg.root.panel.northFixed(m);

    PubSub.sub('core:capturing-status', stat => {
      this.view.capturing = stat.capturing;
      this.view.update();
    });

    PubSub.sub('core:capturing-settings', data => {
      this.view.settings = data;
      this.view.update();
    });
  }

  async deactivate() {
    let pkg = await Package.load('main-view');
    pkg.root.panel.northFixed();
    this.view.unmount();
    this.comp.destroy();
  }
}
