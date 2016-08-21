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
import LoggerInterface from './logger-interface';

class ActionInterface extends EventEmitter {

}

class Dripcap extends EventEmitter {
  constructor(profile) {
    super();
    this.profile = profile;
    this.gold = new GoldFilter();
  }

  _init() {
    let theme = this.profile.getConfig('theme');
    this.config = config;
    this.pubsub = new PubSub();
    this.logger = new LoggerInterface(this);
    this.session = new SessionInterface(this);
    this.theme = new ThemeInterface(this);
    this.package = new PackageInterface(this);
    this.action = new ActionInterface(this);
    this.keybind = new KeybindInterface(this);
    this.menu = new MenuInterface(this);

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

var func = (prof) => {
  let instance = null;
  if (prof != null) {
    instance = new Dripcap(prof);
    instance._init();
  }
  func.Menu = instance.menu;
  func.KeyBind = instance.keybind;
  func.Session = instance.session;
  func.Package = instance.package;
  func.Theme = instance.theme;
  func.Action = instance.action;
  func.PubSub = instance.pubsub;
  func.Profile = instance.profile;
  func.Config = instance.config;
  func.Logger = instance.logger;
  return instance;
};

export default func;
