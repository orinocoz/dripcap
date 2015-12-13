import fs from 'fs'
import path from 'path'
import _ from 'underscore'
require('babel-core/register')({ignore: /.+\/node_modules\/(?!dripper).+\/.+.js/})

export default class Package {
  constructor(jsonPath) {
    this.path = path.dirname(jsonPath)
    let info = JSON.parse(fs.readFileSync(jsonPath))

    if (info.name != null) {
      this.name = info.name
    } else {
      throw new Error('package name required')
    }

    if (info.main != null) {
      this.main = info.main
    } else {
      throw new Error('package main required')
    }

    this.description = info.description
    if (this.description == null) {
      this.description = ''
    }

    this.version = info.version
    if (this.version == null) {
      this.version = '0.0.1'
    }

    this.config = {
      enabled: true
    }

    this._promise = new Promise((resolve) => {
      this._resolve = resolve
    }).then(() => {
      return new Promise((resolve, reject) => {
        let req = path.resolve(this.path, this.main)
        let res = null
        try {
          let klass = require(req)
          this.root = new klass()
          res = this.root.activate()
          this.updateTheme(dripcap.theme.scheme)
        } catch (e) {
          console.error(e)
          reject(e)
          return
        }
        if (res instanceof Promise) {
          res.then(() => {
            resolve(this)
          })
        } else {
          resolve(this)
        }
      })
    })
  }

  load() {
    return this._promise
  }

  activate() {
     this._resolve()
  }

  updateTheme(theme) {
    this.load().then(() => {
      if (this.root != null && this.root.updateTheme != null) {
        this.root.updateTheme(theme)
      }
    })
  }

  deactivate() {
    this.load().then(() => {
      return new Promise((resolve, reject) => {
        try {
          this.root.deactivate()
          this.root = null
          for (let key in require.cache) {
            if (key.startsWith(this.path)) {
              delete require.cache[key]
            }
          }
        } catch (e) {
          reject(e)
          return
        }
        resolve(this)
      })
    })
  }
}
