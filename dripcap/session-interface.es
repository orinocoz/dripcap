import { EventEmitter } from 'events';
import Session from './session';
import config from './config';

export default class SessionInterface extends EventEmitter {
  constructor(parent) {
    super();
    this.parent = parent;
    this.list = [];
    this._dissectors = [];
    this._streamDissectors = [];
    this._classes = [];
  }

  registerDissector(namespaces, path) {
    return this._dissectors.push({namespaces, path});
  }

  registerStreamDissector(namespaces, path) {
    return this._streamDissectors.push({namespaces, path});
  }

  registerClass(name, path) {
    return this._classes.push({name, path});
  }

  unregisterDissector(path) {
    let index = this._dissectors.find(e => e.path === path);
    if (index != null) {
      return this._dissectors.splice(index, 1);
    }
  }

  unregisterStreamDissector(path) {
    let index = this._streamDissectors.find(e => e.path === path);
    if (index != null) {
      return this._streamDissectors.splice(index, 1);
    }
  }

  unregisterClass(path) {
    let index = this._classes.find(e => e.path === path);
    if (index != null) {
      return this._classes.splice(index, 1);
    }
  }

  create(iface, options={}) {
    let sess = new Session(config.filterPath);
    if (iface != null) { sess.addCapture(iface, options); }

    let tasks = [];
    for (let i = 0; i < this._classes.length; i++) {
      let cls = this._classes[i];
      ((cls=cls) => tasks.push(sess.addClass(cls.name, cls.path)))(cls);
    }

    return Promise.all(tasks).then(() => {
      for (let j = 0; j < this._dissectors.length; j++) {
        var dec = this._dissectors[j];
        ((dec=dec) => tasks.push(sess.addDissector(dec.namespaces, dec.path)))(dec);
      }
      for (let k = 0; k < this._streamDissectors.length; k++) {
        var dec = this._streamDissectors[k];
        ((dec=dec) => tasks.push(sess.addStreamDissector(dec.namespaces, dec.path)))(dec);
      }

      return Promise.all(tasks).then(function() {
        dripcap.pubsub.pub('core:capturing-settings', {iface, options});
        return sess;
      });
    }
    );
  }
}
