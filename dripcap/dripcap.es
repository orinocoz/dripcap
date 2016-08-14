import config from './config';
import $ from 'jquery';
import less from 'less';
import GoldFilter from 'goldfilter';
import {
  EventEmitter
} from 'events';

import PubSub from './pubsub';
import SessionInterface from './session-interface';
import ThemeInterface from './theme-interface';
import KeybindInterface from './keybind-interface';
import PackageInterface from './package-interface';
import MenuInterface from './menu-interface';

class ActionInterface extends EventEmitter {

}

class EventInterface extends EventEmitter {

}

class Dripcap extends EventEmitter {
  constructor(profile) {
    super();
    this.profile = profile;
    this._gold = new GoldFilter();
    global.dripcap = this;
  }

  getInterfaceList() {
    return this._gold.devices();
  }

  _init() {
    let theme = this.profile.getConfig('theme');
    this.config = config;
    this.session = new SessionInterface(this);
    this.theme = new ThemeInterface(this);
    this.keybind = new KeybindInterface(this);
    this.package = new PackageInterface(this);
    this.action = new ActionInterface(this);
    this.event = new EventInterface(this);
    this.menu = new MenuInterface(this);
    this.pubsub = new PubSub()

    this._css = $('<style>').appendTo($('head'));
    this.theme.sub('update', (scheme) => {
      let compLess = '';
      for (let l of scheme.less) {
        compLess += `@import "${l}";\n`;
      }
      this._css.attr('name', scheme.name)
      less.render(compLess, (e, output) => {
        if (e != null) {
          throw e;
        } else if (this._css.attr('name') === scheme.name) {
          this._css.text(output.css);
        }
      });
    });

    this.theme.id = theme;

    this.package.updatePackageList();
    this.profile.init();

    $(window).on('unload', () => {
      for (k in this.package.loadedPackages) {
        let pkg = this.package.loadedPackages[k];
        pkg.deactivate();
      }
    });
  }
}

export default (prof) => {
  let instance = null;
  if (prof != null) {
    instance = new Dripcap(prof);
    instance._init();
  }
  return instance;
};
