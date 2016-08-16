import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import {
  remote
} from 'electron';
let {
  MenuItem
} = remote;
import {
  KeyBind,
  Menu,
  Package,
  Action,
  PubSub
} from 'dripcap';

export default class SessionDialog {
  activate() {
    return new Promise(res => {
      KeyBind.bind('command+n', '!menu', 'core:new-session');

      this.captureMenu = function(menu, e) {
        let left;
        let action = name => () => Action.emit(name);
        let capturing = (left = PubSub.get('core:capturing-status')) != null ? left : false;
        menu.append(new MenuItem({
          label: 'New Session',
          accelerator: KeyBind.get('!menu', 'core:new-session'),
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

      Menu.registerMain('Capture', this.captureMenu);
      PubSub.sub('core:capturing-status', () => Menu.updateMainMenu());

      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return Package.load('main-view').then(pkg => {
        return Package.load('modal-dialog').then(pkg => {
          return $(() => {
            let n = $('<div>').addClass('container').appendTo($('body'));
            this.view = riot.mount(n[0], 'session-dialog')[0];

            KeyBind.bind('enter', '[riot-tag=session-dialog] .content', () => {
              return $(this.view.tags['modal-dialog'].start).click();
            });

            dripcap.getInterfaceList().then(list => {
              this.view.setInterfaceList(list);
              return this.view.update();
            });

            Action.on('core:new-session', () => {
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
    Menu.unregisterMain('Capture', this.captureMenu);
    KeyBind.unbind('command+n', '!menu', 'core:new-session');
    KeyBind.unbind('enter', '[riot-tag=session-dialog] .content');
    this.view.unmount();
    return this.comp.destroy();
  }
}
