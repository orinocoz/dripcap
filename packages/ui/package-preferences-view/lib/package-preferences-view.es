import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';

export default class PackagePreferencesView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      dripcap.package.load('preferences-dialog').then(pkg => {
        return $(() => {
          let m = $('<div class="wrapper"/>');
          this._view = riot.mount(m[0], 'package-preferences-view')[0];
          pkg.root.panel.center('package', m, $('<i class="fa fa-gift"> Packages</i>'));

          return dripcap.package.sub('core:package-list-updated', list => {
            this._view.packageList = Object.keys(list).map(v => list[v]);
            return this._view.update();
          }
          );
        }
        );
      }
      );
      return res();
    }
    );
  }

  deactivate() {
    this._view.unmount();
    return this.comp.destroy();
  }
}
