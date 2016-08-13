import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';

export default class PreferencesDialog {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return dripcap.package.load('main-view').then(pkg => {
        return dripcap.package.load('modal-dialog').then(pkg => {
          return $(() => {
            this.panel = new Panel();
            let n = $('<div>').appendTo($('body'));
            this._view = riot.mount(n[0], 'preferences-dialog')[0];
            $(this._view.root).find('.content').append($('<div class="root-container" />').append(this.panel.root));

            dripcap.action.on('core:preferences', () => {
              this._view.show();
              return this._view.update();
            }
            );

            return res();
          }
          );
        }
        );
      }
      );
    }
    );
  }

  deactivate() {
    dripcap.keybind.unbind('enter', '[riot-tag=preferences-dialog] .content');
    this._view.unmount();
    return this.comp.destroy();
  }
}
