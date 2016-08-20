import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  Package
} from 'dripcap';

export default class PackagePreferencesView {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
    let pkg = await Package.load('preferences-dialog');

    let m = $('<div class="wrapper"/>');
    this._view = riot.mount(m[0], 'package-preferences-view')[0];
    pkg.root.panel.center('package', m, $('<i class="fa fa-gift"> Packages</i>'));

    Package.sub('core:package-list-updated', list => {
      this._view.packageList = Object.keys(list).map(v => list[v]);
      this._view.update();
    });
  }

  async deactivate() {
    this._view.unmount();
    this.comp.destroy();
  }
}
