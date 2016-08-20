import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  Package
} from 'dripcap';

export default class InstallPreferencesView {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
    let pkg = await Package.load('preferences-dialog');
    let m = $('<div class="wrapper"/>');
    this._view = riot.mount(m[0], 'install-preferences-view')[0];
    pkg.root.panel.center('install', m, $('<i class="fa fa-cloud-download"> Install</i>'));
  }

  async deactivate() {
    this._view.unmount();
    this.comp.destroy();
  }
}
