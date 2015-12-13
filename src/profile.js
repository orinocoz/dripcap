import fs from 'fs'
import path from 'path'
import JSON5 from 'json5'
import mkpath from 'mkpath'
import _ from 'underscore'

class Category {
  constructor(_name, _path, defaultValue = {}) {
    this._name = _name
    this._path = _path
    this._handlers = {}

    try {
      this._data = JSON5.parse(fs.readFileSync(this._path))
    } catch (e) {
      console.warn(e)
      this._data = defaultValue
      this._save()
    }
  }

  get(key) {
    return this._data[key]
  }

  set(key, value) {
    if (!_.isEqual(value, this._data[key])) {
      this._data[key] = value
      if (this._handlers[key] != null) {
        for (let h of this._handlers[key]) {
          h(value)
        }
      }
      this._save()
    }
  }

  watch(key, handler) {
    if (!this._handlers[key]) {
      this._handlers[key] = []
    }
    this._handlers[key].push(handler)
    _.uniq(this._handlers[key])
  }

  unwatch(key, handler) {
    if (!this._handlers[key]) {
      this._handlers[key] = []
    }
    this._handlers[key] = _.without(this._handlers[key], handler)
  }

  _save() {
    fs.writeFileSync(this._path, JSON5.stringify(this._data))
  }
}

export default class Profile {
  constructor(_path) {
    this.path = _path

    mkpath.sync(this.path)
    this._initPath = path.join(this.path, '/init.js')

    this._config = new Category('config', path.join(this.path, '/config.json5'))
    this._package = new Category('package', path.join(this.path,'/package.json5'))
    this._layout = new Category('layout', path.join(this.path,'/layout.json5'))
  }

  getConfig(key) {
    return this._config.get(key)
  }

  setConfig(key, value) {
    this._config.set(key, value)
  }

  watchConfig(key, handler) {
    this._config.watch(key, handler)
  }

  unwatchConfig(key, handler) {
    this._config.unwatch(key, handler)
  }

  getPackage(key) {
    return this._package.get(key)
  }

  setPackage(key, value) {
    this._package.set(key, value)
  }

  watchPackage(key, handler) {
    this._package.watch(key, handler)
  }

  unwatchPackage(key, handler) {
    this._package.unwatch(key, handler)
  }

  getLayout(key) {
    return this._layout.get(key)
  }

  setLayout(key, value) {
    this._layout.set(key, value)
  }

  watchLayout(key, handler) {
    this._layout.watch(key, handler)
  }

  unwatchLayout(key, handler) {
    this._layout.unwatch(key, handler)
  }

  init() {
    try {
      require(this._initPath)
    } catch (e) {
      if (e.code !== "MODULE_NOT_FOUND") {
        console.warn(e)
      }
    }
  }
}
