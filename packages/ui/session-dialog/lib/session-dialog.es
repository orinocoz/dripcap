import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  remote
} from 'electron';
let {
  MenuItem
} = remote;

export default class SessionDialog {
  activate() {
    return new Promise(res => {
      dripcap.keybind.bind('command+n', '!menu', 'core:new-session');

      this.captureMenu = function(menu, e) {
        let left;
        let action = name => () => dripcap.action.emit(name);
        let capturing = (left = dripcap.pubsub.get('core:capturing-status')) != null ? left : false;
        menu.append(new MenuItem({
          label: 'New Session',
          accelerator: dripcap.keybind.get('!menu', 'core:new-session'),
          click: action('core:new-session')
        }));
        menu.append(new MenuItem({
          type: 'separator'
        }));
        menu.append(new MenuItem({
          label: 'Start',
          enabled: !capturing,
          click: action('core:start-sessions')
        }));
        menu.append(new MenuItem({
          label: 'Stop',
          enabled: capturing,
          click: action('core:stop-sessions')
        }));
        return menu;
      };

      dripcap.menu.registerMain('Capture', this.captureMenu);
      dripcap.pubsub.sub('core:capturing-status', () => dripcap.menu.updateMainMenu());

      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return dripcap.package.load('main-view').then(pkg => {
        return dripcap.package.load('modal-dialog').then(pkg => {
          return $(() => {
            let n = $('<div>').addClass('container').appendTo($('body'));
            this.view = riot.mount(n[0], 'session-dialog')[0];

            dripcap.keybind.bind('enter', '[riot-tag=session-dialog] .content', () => {
              return $(this.view.tags['modal-dialog'].start).click();
            });

            dripcap.getInterfaceList().then(list => {
              this.view.setInterfaceList(list);
              return this.view.update();
            });

            dripcap.action.on('core:new-session', () => {
              return dripcap.getInterfaceList().then(list => {
                this.view.setInterfaceList(list);
                this.view.show();
                return this.view.update();
              });
            });

            return res();
          });
        });
      });
    });
  }

  deactivate() {
    dripcap.menu.unregisterMain('Capture', this.captureMenu);
    dripcap.keybind.unbind('command+n', '!menu', 'core:new-session');
    dripcap.keybind.unbind('enter', '[riot-tag=session-dialog] .content');
    this.view.unmount();
    return this.comp.destroy();
  }
}
