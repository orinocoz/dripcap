import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';

export default class GeneralPreferencesView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      dripcap.package.load('preferences-dialog').then(pkg => {
        return $(() => {
          let m = $('<div class="wrapper"/>');
          this._view = riot.mount(m[0], 'general-preferences-view')[0];
          pkg.root.panel.center('general', m, $('<i class="fa fa-cog"> General</i>'));

          dripcap.theme.sub('registryUpdated', () => {
            this._view.setThemeList(dripcap.theme.registry);
            return this._view.update();
          }
          );

          dripcap.profile.watchConfig('theme', id => {
            this._view.currentTheme = id;
            return this._view.update();
          }
          );

          return dripcap.profile.watchConfig('snaplen', len => {
            this._view.currentSnaplen = len;
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
