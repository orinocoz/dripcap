import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';

export default class InstallPreferencesView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      dripcap.package.load('preferences-dialog').then(pkg => {
        return $(() => {
          let m = $('<div class="wrapper"/>');
          this._view = riot.mount(m[0], 'install-preferences-view')[0];
          return pkg.root.panel.center('install', m, $('<i class="fa fa-cloud-download"> Install</i>'));
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
