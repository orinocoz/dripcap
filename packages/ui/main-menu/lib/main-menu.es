import $ from 'jquery';
import fs from 'fs';
import { remote } from 'electron';
let { app } = remote;
let Menu = remote.menu;
let { MenuItem } = remote;

export default class MainMenu {
  activate() {
    return new Promise(res => {
      let action = name => () => dripcap.action.emit(name);

      dripcap.keybind.bind('command+shift+n', '!menu', 'core:new-window');
      dripcap.keybind.bind('command+shift+w', '!menu', 'core:close-window');
      dripcap.keybind.bind('command+q', '!menu', 'core:quit');
      dripcap.keybind.bind('command+,', '!menu', 'core:preferences');
      dripcap.keybind.bind('command+shift+i', '!menu', 'core:toggle-devtools');
      dripcap.keybind.bind('command+m', '!menu', 'core:window-minimize');
      dripcap.keybind.bind('command+alt+ctrl+m', '!menu', 'core:window-zoom');

      this.fileMenu = function(menu, e) {
        menu.append(new MenuItem({label: 'New Window', accelerator: dripcap.keybind.get('!menu', 'core:new-window'), click: action('core:new-window')}));
        menu.append(new MenuItem({label: 'Close Window', accelerator: dripcap.keybind.get('!menu', 'core:close-window'), click: action('core:close-window')}));
        if (process.platform !== 'darwin') {
          menu.append(new MenuItem({type: 'separator'}));
          menu.append(new MenuItem({label: 'Quit', accelerator: dripcap.keybind.get('!menu', 'core:quit'), click: action('core:quit')}));
        }
        return menu;
      };

      this.editMenu = function(menu, e) {
        if (process.platform === 'darwin') {
          menu.append(new MenuItem({label: 'Cut', accelerator: 'Cmd+X', selector: 'cut:'}));
          menu.append(new MenuItem({label: 'Copy', accelerator: 'Cmd+C', selector: 'copy:'}));
          menu.append(new MenuItem({label: 'Paste', accelerator: 'Cmd+V', selector: 'paste:'}));
          menu.append(new MenuItem({label: 'Select All', accelerator: 'Cmd+A', selector: 'selectAll:'}));
        } else {
          let contents = remote.getCurrentWebContents();
          menu.append(new MenuItem({label: 'Cut', accelerator: 'Ctrl+X', click() { return contents.cut(); }}));
          menu.append(new MenuItem({label: 'Copy', accelerator: 'Ctrl+C', click() { return contents.copy(); }}));
          menu.append(new MenuItem({label: 'Paste', accelerator: 'Ctrl+V', click() { return contents.paste(); }}));
          menu.append(new MenuItem({label: 'Select All', accelerator: 'Ctrl+A', click() { return contents.selectAll(); }}));
        }
        if (process.platform !== 'darwin') {
          menu.append(new MenuItem({type: 'separator'}));
          menu.append(new MenuItem({label: 'Preferences', accelerator: dripcap.keybind.get('!menu', 'core:preferences'), click: action('core:preferences')}));
        }
        return menu;
      };

      this.devMenu = function(menu, e) {
        menu.append(new MenuItem({label: 'Toggle DevTools', accelerator: dripcap.keybind.get('!menu', 'core:toggle-devtools'), click: action('core:toggle-devtools')}));
        menu.append(new MenuItem({label: 'Open User Directory', click: action('core:open-user-directroy')}));
        return menu;
      };

      this.windowMenu = function(menu, e) {
        menu.append(new MenuItem({label: 'Minimize', accelerator: dripcap.keybind.get('!menu', 'core:window-minimize'), role: 'minimize'}));
        if (process.platform === 'darwin') {
          menu.append(new MenuItem({label: 'Zoom', accelerator: dripcap.keybind.get('!menu', 'core:window-zoom'), click: action('core:window-zoom')}));
          menu.append(new MenuItem({type: 'separator'}));
          menu.append(new MenuItem({label: 'Bring All to Front', accelerator: dripcap.keybind.get('!menu', 'core:window-front'), role: 'front'}));
        }
        return menu;
      };

      this.helpMenu = function(menu, e) {
        menu.append(new MenuItem({label: 'Visit Website', click: action('core:open-website')}));
        menu.append(new MenuItem({label: 'Visit Wiki', click: action('core:open-wiki')}));
        menu.append(new MenuItem({label: 'Show License', click: action('core:show-license')}));
        if (process.platform !== 'darwin') {
          menu.append(new MenuItem({type: 'separator'}));
          menu.append(new MenuItem({label: `Version ${dripcap.config.version}`, enabled: false}));
        }
        return menu;
      };

      if (process.platform === 'darwin') {
        this.appMenu = function(menu, e) {
          menu.append(new MenuItem({label: `Version ${dripcap.config.version}`, enabled: false}));
          menu.append(new MenuItem({type: 'separator'}));
          menu.append(new MenuItem({label: 'Preferences', accelerator: dripcap.keybind.get('!menu', 'core:preferences'), click: action('core:preferences')}));
          return menu;
        };
        this.quitMenu = function(menu, e) {
          menu.append(new MenuItem({label: 'Quit', accelerator: dripcap.keybind.get('!menu', 'core:quit'), click: action('core:quit')}));
          return menu;
        };
        let name = app.getName();
        dripcap.menu.registerMain(name, this.appMenu);
        dripcap.menu.registerMain(name, this.devMenu);
        dripcap.menu.registerMain(name, this.quitMenu);
        dripcap.menu.setMainPriority(name, 999);
      }

      if (process.platform !== 'darwin') {
        dripcap.menu.registerMain('Developer', this.devMenu);
      }

      dripcap.menu.registerMain('File', this.fileMenu);
      dripcap.menu.registerMain('Edit', this.editMenu);
      dripcap.menu.registerMain('Window', this.windowMenu);
      dripcap.menu.registerMain('Help', this.helpMenu);
      dripcap.menu.setMainPriority('Help', -999);

      dripcap.theme.sub('registryUpdated', () => dripcap.menu.updateMainMenu()
      );

      dripcap.keybind.on('update', () => dripcap.menu.updateMainMenu()
      );

      return res();
    }
    );
  }

  deactivate() {
    dripcap.keybind.unbind('command+shift+n', '!menu', 'core:new-window');
    dripcap.keybind.unbind('command+shift+w', '!menu', 'core:close-window');
    dripcap.keybind.unbind('command+q', '!menu', 'core:quit');
    dripcap.keybind.unbind('command+,', '!menu', 'core:preferences');
    dripcap.keybind.unbind('command+shift+i', '!menu', 'core:toggle-devtools');
    dripcap.keybind.unbind('command+m', '!menu', 'core:window-minimize');
    dripcap.keybind.unbind('command+alt+ctrl+i', '!menu', 'core:window-zoom');

    if (process.platform === 'darwin') {
      let name = app.getName();
      dripcap.menu.unregisterMain(name, this.appMenu);
      dripcap.menu.registerMain(name, this.devMenu);
      dripcap.menu.registerMain(name, this.quitMenu);
    } else {
      dripcap.menu.unregisterMain('Developer', this.devMenu);
    }

    dripcap.menu.unregisterMain('File', this.fileMenu);
    dripcap.menu.unregisterMain('Edit', this.editMenu);
    dripcap.menu.unregisterMain('Window', this.windowMenu);
    return dripcap.menu.unregisterMain('Help', this.helpMenu);
  }
}
