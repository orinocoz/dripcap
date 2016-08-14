import {
  EventEmitter
} from 'events';
import _ from 'underscore';
import {
  remote
} from 'electron';
let {
  Menu
} = remote;
let {
  MenuItem
} = remote;

export default class MenuInterface extends EventEmitter {
  constructor(parent) {
    super();
    this.parent = parent;
    this._handlers = {};
    this._mainHadlers = {};
    this._mainPriorities = {};

    this._updateMainMenu = _.debounce(() => {
      let root = new Menu();
      let keys = Object.keys(this._mainHadlers);
      keys.sort((a, b) => (this._mainPriorities[b] || 0) - (this._mainPriorities[a] || 0));
      for (let j = 0; j < keys.length; j++) {
        let k = keys[j];
        let menu = new Menu();
        for (let i = 0; i < this._mainHadlers[k].length; i++) {
          let h = this._mainHadlers[k][i];
          menu = h.handler.call(this, menu);
          if (i < this._mainHadlers[k].length - 1) {
            menu.append(new MenuItem({
              type: 'separator'
            }));
          }
        }
        let item = {
          label: k,
          submenu: menu,
          type: 'submenu'
        };
        switch (k) {
          case 'Help':
            item.role = 'help';
            break;
          case 'Window':
            item.role = 'window';
            break;
        }
        root.append(new MenuItem(item));
      }

      if (process.platform !== 'darwin') {
        return remote.getCurrentWindow().setMenu(root);
      } else {
        return Menu.setApplicationMenu(root);
      }
    }, 100);
  }

  register(name, handler, priority = 0) {
    if (this._handlers[name] == null) {
      this._handlers[name] = [];
    }
    this._handlers[name].push({
      handler,
      priority
    });
    return this._handlers[name].sort((a, b) => b.priority - a.priority);
  }

  unregister(name, handler) {
    if (this._handlers[name] == null) {
      this._handlers[name] = [];
    }
    return this._handlers[name] = this._handlers[name].filter(h => h.handler !== handler);
  }

  registerMain(name, handler, priority = 0) {
    if (this._mainHadlers[name] == null) {
      this._mainHadlers[name] = [];
    }
    this._mainHadlers[name].push({
      handler,
      priority
    });
    this._mainHadlers[name].sort((a, b) => b.priority - a.priority);
    return this.updateMainMenu();
  }

  unregisterMain(name, handler) {
    if (this._mainHadlers[name] == null) {
      this._mainHadlers[name] = [];
    }
    this._mainHadlers[name] = this._mainHadlers[name].filter(h => h.handler !== handler);
    return this.updateMainMenu();
  }

  setMainPriority(name, priority) {
    return this._mainPriorities[name] = priority;
  }

  updateMainMenu() {
    return this._updateMainMenu();
  }

  popup(name, self, browserWindow, x, y) {
    if (this._handlers[name] != null) {
      let menu = new Menu();
      let handlers = this._handlers[name];
      for (let i = 0; i < handlers.length; i++) {
        let h = handlers[i];
        menu = h.handler.call(self, menu);
        if (i < handlers.length - 1) {
          menu.append(new MenuItem({
            type: 'separator'
          }));
        }
      }
      return menu.popup(browserWindow, x, y);
    }
  }
}
