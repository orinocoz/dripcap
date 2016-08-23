import fs from 'fs';
import path from 'path';
import mkpath from 'mkpath';
import _ from 'underscore';

class Category {
  constructor(_path, defaultValue = {}) {
    this._path = _path;
    try {
      this._data = JSON.parse(fs.readFileSync(this._path));
    } catch (e) {
      if (e.code !== 'ENOENT') {
        console.warn(e);
      }
      this._data = defaultValue;
      this._save();
    }

    this._data = _.extend(defaultValue, this._data);
    this._handlers = {};
  }

  get(key, def = null) {
    if (this._data[key] === undefined) {
      return null;
    }
    return this._data[key];
  }

  set(key, value) {
    if (!_.isEqual(value, this._data[key])) {
      this._data[key] = value;
      if (this._handlers[key] != null) {
        for (let i = 0; i < this._handlers[key].length; i++) {
          let h = this._handlers[key][i];
          h(value);
        }
      }
      return this._save();
    }
  }

  watch(key, handler) {
    if (this._handlers[key] == null) {
      this._handlers[key] = [];
    }
    this._handlers[key].push(handler);
    return _.uniq(this._handlers[key]);
  }

  unwatch(key, handler) {
    if (this._handlers[key] != null) {
      return this._handlers[key] = _.without(this._handlers[key], handler);
    }
  }

  _save() {
    return fs.writeFileSync(this._path, JSON.stringify(this._data, null, '  '));
  }
}

export default class Profile {
  constructor(path1) {
    this.path = path1;
    this._packagePath = path.join(this.path, 'packages');
    mkpath.sync(this.path);
    mkpath.sync(this._packagePath);

    this._initPath = path.join(this.path, 'init.coffee');

    this._config = new Category(path.join(this.path, 'config.json'), {
      snaplen: 1600,
      theme: 'default',
      "package-registry": 'socket.moe',
      startupDialog: true
    });

    this._packages = {};

    try {
      this._keyMap = JSON.parse(fs.readFileSync(path.join(this.path, 'keymap.json')));
    } catch (e) {
      if (e.code !== 'ENOENT') {
        console.warn(e);
      }
      this._keyMap = {};
    }
  }

  getConfig(key) {
    return this._config.get(key);
  }
  setConfig(key, value) {
    return this._config.set(key, value);
  }
  watchConfig(key, handler) {
    return this._config.watch(key, handler);
  }
  unwatchConfig(key, handler) {
    return this._config.unwatch(key, handler);
  }

  getKeymap() {
    return this._keyMap;
  }

  getPackageConfig(name) {
    if (this._packages[name] == null) {
      this._packages[name] = new Category(path.join(this._packagePath, `${name}.json`), {
        enabled: true
      });
    }
    return this._packages[name];
  }

  init() {
    try {
      return require(this._initPath);
    } catch (e) {
      if (e.code !== "MODULE_NOT_FOUND") {
        return console.warn(e);
      }
    }
  }
}
