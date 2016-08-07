import path from 'path';
import glob from 'glob';
import rebuild from 'electron-rebuild';
import npm from 'npm';
import semver from 'semver';
import fs from 'fs';
import zlib from 'zlib';
import tar from 'tar';
import request from 'request';
import rmdir from 'rmdir';
import _ from 'underscore';

import PubSub from './pubsub';
import Package from './pkg';
import config from './config';

export default class PackageInterface extends PubSub {
  constructor(parent) {
    super();
    this.parent = parent;
    this.uninstall = this.uninstall.bind(this);
    this.list = {};
    this.triggerlLoaded = _.debounce(() => {
      return this.pub('core:package-loaded');
    }
    , 500);
  }

  load(name) {
    let pkg = this.list[name];
    if (pkg == null) { throw new Error(`package not found: ${name}`); }
    return pkg.load();
  }

  unload(name) {
    let pkg = this.list[name];
    if (pkg == null) { throw new Error(`package not found: ${name}`); }
    return pkg.deactivate();
  }

  updatePackageList() {
    let paths = glob.sync(config.packagePath + '/**/package.json');
    paths = paths.concat(glob.sync(config.userPackagePath + '/**/package.json'));

    let loadedPackages = {};

    for (let i = 0; i < paths.length; i++) {
      let p = paths[i];
      try {
        let loaded;
        var pkg = new Package(p);
        loadedPackages[pkg.name] = true;

        if ((loaded = this.list[pkg.name]) != null) {
          if (loaded.path !== pkg.path) {
            console.warn(`package name conflict: ${pkg.name}`);
            continue;
          } else if (semver.gte(loaded.version, pkg.version)) {
            continue;
          } else {
            loaded.deactivate();
          }
        }

        this.list[pkg.name] = pkg;
      } catch (e) {
        console.warn(`failed to load ${pkg.name}/package.json : ${e}`);
      }
    }

    for (let k in this.list) {
      var pkg = this.list[k];
      if (!loadedPackages[pkg.name]) {
        delete this.list[k];
      } else if (pkg.config.get('enabled')) {
        pkg.activate();
        pkg.load().then(() => {
          return process.nextTick(() => this.triggerlLoaded());
        }
        );
      }
    }

    return this.pub('core:package-list-updated', this.list);
  }

  updateTheme(scheme) {
    for (k in this.list) {
      let pkg = this.list(k);
      if (pkg.config.get('enabled'))
        pkg.updateTheme(scheme);
    }
  }

  rebuild(path) {
    let ver = config.electronVersion;
    return rebuild.installNodeHeaders(ver).then(() =>
      rebuild.rebuildNativeModules(ver, config.packagePath).then(() => rebuild.rebuildNativeModules(ver, config.userPackagePath))
    );
  }

  install(name) {
    let registry = dripcap.profile.getConfig('package-registry');
    let pkgpath = path.join(config.userPackagePath, name);
    let tarurl = '';

    let p = Promise.resolve().then(() => {
      if (this.list[name] != null) {
        throw Error(`Package ${name} is already installed`);
      }

      return new Promise((res, rej) =>
        npm.load({production: true, registry}, () =>
          npm.commands.view([name], function(e, data) {
            try {
              if (e != null) { throw e; }
              let pkg = data[Object.keys(data)[0]];
              if ((pkg.engines != null) && (pkg.engines.dripcap != null)) {
                let ver = pkg.engines.dripcap;
                if (semver.satisfies(config.version, ver)) {
                  if ((pkg.dist != null) && (pkg.dist.tarball != null)) {
                    tarurl = pkg.dist.tarball;
                    return res();
                  } else {
                    throw new Error('Tarball not found');
                  }
                } else {
                  throw new Error('Dripcap version mismatch');
                }
              } else {
                throw new Error('This package is not for dripcap');
              }
            } catch (e) {
              return rej(e);
            }
          }
          )

        )
      );
    }
    );

    p = p.then(() => {
      return new Promise(res => fs.stat(pkgpath, e => res(e)))
      .then(e => {
        if (e != null) {
          return Promise.resolve();
        } else {
          return this.uninstall(name);
        }
      }
      );
    }
    );

    p = p.then(() =>
      new Promise(function(res) {
        let gunzip = zlib.createGunzip();
        let extractor = tar.Extract({path: pkgpath, strip: 1});
        return request(tarurl).pipe(gunzip).pipe(extractor).on('finish', () => res());
      })
    );

    p = p.then(() =>
      new Promise(function(res) {
        let jsonPath = path.join(pkgpath, 'package.json');
        return fs.readFile(jsonPath, function(err, data) {
          if (err) { throw err; }
          let json = JSON.parse(data);
          json['_dripcap'] = {name, registry};
          return fs.writeFile(jsonPath, JSON.stringify(json, null, '  '), function(err) {
            if (err) { throw err; }
            return res();
          }
          );
        }
        );
      })
    );

    return p.then(() => {
      return new Promise(res => {
        return npm.commands.install(pkgpath, [], () => {
          res();
          return this.updatePackageList();
        }
        );
      }
      );
    }
    );
  }

  uninstall(name) {
    let pkgpath = path.join(config.userPackagePath, name);
    return new Promise(res => {
      return rmdir(pkgpath, err => {
        this.updatePackageList();
        if (err != null) { throw err; }
        return res();
      }
      );
    }
    );
  }
}
