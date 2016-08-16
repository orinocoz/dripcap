import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  Package,
  Theme,
  Profile
} from 'dripcap';

export default class GeneralPreferencesView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      Package.load('preferences-dialog').then(pkg => {
        return $(() => {
          let m = $('<div class="wrapper"/>');
          this._view = riot.mount(m[0], 'general-preferences-view')[0];
          pkg.root.panel.center('general', m, $('<i class="fa fa-cog"> General</i>'));

          Theme.sub('registryUpdated', () => {
            this._view.setThemeList(Theme.registry);
            return this._view.update();
          });

          Profile.watchConfig('theme', id => {
            this._view.currentTheme = id;
            return this._view.update();
          });

          return Profile.watchConfig('snaplen', len => {
            this._view.currentSnaplen = len;
            return this._view.update();
          });
        });
      });
      return res();
    });
  }

  deactivate() {
    this._view.unmount();
    return this.comp.destroy();
  }
}
