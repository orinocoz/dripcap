import fs from 'fs';
import path from 'path';
import _ from 'underscore';
import config from 'dripcap/config';
import babelTemplate from 'babel-template';

function globalPaths() {
  return {
    visitor: {
      Program: {
        exit: function(p) {
          let modulePath = path.resolve(__dirname, '..').split(path.sep).join('/');
          let code = `require('module').globalPaths.push('${modulePath}');`;
          let node = babelTemplate(code)();
          p.unshiftContainer('body', [node]);
        },
      },
    },
  };
}

require("babel-register")({
  extensions: [".es"],
  plugins: ["add-module-exports", [
      "transform-es2015-modules-commonjs", {
        "allowTopLevelThis": true
      }
    ],
    "transform-async-to-generator", globalPaths
  ]
});

export default class Package {
  constructor(jsonPath, profile) {
    this.path = path.dirname(jsonPath);
    this.userPackage = path.normalize(this.path).startsWith(path.normalize(config.userPackagePath));

    let info = JSON.parse(fs.readFileSync(jsonPath));

    if (info.name != null) {
      this.name = info.name;
    } else {
      throw new Error('package name required');
    }

    if ((info._dripcap != null) && (info._dripcap.name != null)) {
      this.name = info._dripcap.name;
    }

    if (info.main != null) {
      this.main = info.main;
    } else {
      throw new Error('package main required');
    }

    this.description = info.description != null ? info.description : '';
    this.version = info.version != null ? info.version : '0.0.1';
    this.config = profile.getPackageConfig(this.name);
    this._reset();
  }

  _reset() {
    return this._promise =
      new Promise(resolve => {
        return this._resolve = resolve;
      })
      .then(() => {
        return new Promise((resolve, reject) => {
          let req = path.resolve(this.path, this.main);
          let res = null;

          const cwd = process.cwd();
          process.chdir(__dirname);
          try {
            let klass = require(req);
            if (klass.__esModule) {
              klass = klass.default;
            }
            this.root = new klass(this);
            res = this.root.activate();
          } catch (e) {
            reject(e);
            return;
          } finally {
            process.chdir(cwd);
          }

          if (res instanceof Promise) {
            return res.then(() => resolve(this));
          } else {
            return resolve(this);
          }
        });
      });
  }

  load() {
    return this._promise;
  }

  activate() {
    return this._resolve();
  }

  renderPreferences() {
    if ((this.root != null) && (this.root.renderPreferences != null)) {
      return this.root.renderPreferences();
    } else {
      return null;
    }
  }

  async deactivate() {
    await this.load();
    return new Promise((resolve, reject) => {
      try {
        this.root.deactivate();
        this.root = null;
        this._reset();
        for (let key in require.cache) {
          if (key.startsWith(this.path)) {
            delete require.cache[key];
          }
        }
      } catch (e) {
        reject(e);
        return;
      }
      return resolve(this);
    });
  }
}
