import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';
import {
  Package,
  Menu,
  PubSub,
  Config,
  Logger,
  Action
} from 'dripcap';
import {
  remote
} from 'electron';
let {
  MenuItem,
  app
} = remote;

export default class LogView {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
    let pkg = await Package.load('main-view');
    this.base = $('<div class="wrapper" />').attr('tabIndex', '0');
    this.view = riot.mount(this.base[0], 'log-view')[0];
    this.list = $(this.view.root).find('ul');

    this.active = false;
    this.toggleMenu = (menu, e) => {
      menu.append(new MenuItem({
        label: 'Toggle Log Panel',
        type: 'checkbox',
        checked: this.active,
        click: () => {
          Action.emit('log-view:toggle');
        }
      }));
      return menu;
    };

    if (process.platform === 'darwin') {
      Menu.registerMain(app.getName(), this.toggleMenu);
    } else {
      Menu.registerMain('Developer', this.toggleMenu);
    }

    Action.on('log-view:toggle', () => {
      if (this.active) {
        pkg.root.panel.bottom('log-view');
      } else {
        pkg.root.panel.bottom('log-view', this.base, $('<i class="fa fa-file-text"> Log</i>'));
      }
      this.active = !this.active;
    });

    PubSub.sub('core:log', (log) => {
      let textClass = '';
      switch (log.level) {
        case 'debug':
          textClass = 'text-label';
          break;
        case 'warn':
          textClass = 'text-headline';
          break;
        case 'error':
          textClass = 'text-warn';
          break;
      }
      let hours = ('0' + log.timestamp.getHours()).slice(-2);
      let minutes = ('0' + log.timestamp.getMinutes()).slice(-2);
      let seconds = ('0' + log.timestamp.getSeconds()).slice(-2);
      let date = `[${hours}:${minutes}:${seconds}]`;
      this.list.append($('<li>').addClass(textClass).append($('<span>').text(date)).append(document.createTextNode(log.message)));
    });

    Logger.info('log-view loaded');
  }

  async deactivate() {
    let pkg = await Package.load('main-view');
    pkg.root.panel.bottom('log-view');
    this.view.unmount();
    this.comp.destroy();
    if (process.platform === 'darwin') {
      Menu.unregisterMain(app.getName(), this.toggleMenu);
    } else {
      Menu.unregisterMain('Developer', this.toggleMenu);
    }
  }
}
