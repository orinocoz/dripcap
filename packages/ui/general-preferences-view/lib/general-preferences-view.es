import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  Package,
  Theme,
  Profile
} from 'dripcap';

export default class GeneralPreferencesView {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
    let pkg = await Package.load('preferences-dialog');
    let m = $('<div class="wrapper"/>');
    this._view = riot.mount(m[0], 'general-preferences-view')[0];
    pkg.root.panel.center('general', m, $('<i class="fa fa-cog"> General</i>'));

    Theme.sub('registryUpdated', () => {
      this._view.setThemeList(Theme.registry);
      this._view.update();
    });

    Profile.watchConfig('theme', id => {
      this._view.currentTheme = id;
      this._view.update();
    });

    Profile.watchConfig('snaplen', len => {
      this._view.currentSnaplen = len;
      this._view.update();
    });
  }

  async deactivate() {
    this._view.unmount();
    this.comp.destroy();
  }
}
