import path from 'path';
import glob from 'glob';
import rebuild from 'electron-rebuild';
import npm from 'npm';
import semver from 'semver';
import fs from 'fs';
import zlib from 'zlib';
import tar from 'tar';
import url from 'url';
import dns from 'dns';
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
      this.pub('core:package-loaded');
    }, 500);
  }

  load(name) {
    let pkg = this.list[name];
    if (pkg == null) {
      throw new Error(`package not found: ${name}`);
    }
    return pkg.load();
  }

  unload(name) {
    let pkg = this.list[name];
    if (pkg == null) {
      throw new Error(`package not found: ${name}`);
    }
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
        var pkg = new Package(p, this.parent.profile);
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
          process.nextTick(() => this.triggerlLoaded());
        });
      }
    }

    this.pub('core:package-list-updated', this.list);
  }

  rebuild(path) {
    let ver = config.electronVersion;
    return rebuild.installNodeHeaders(ver).then(() =>
      rebuild.rebuildNativeModules(ver, config.packagePath).then(() => rebuild.rebuildNativeModules(ver, config.userPackagePath))
    );
  }

  resolveRegistry(hostname) {
    return new Promise((res, rej) => {
      dns.resolveSrv('_dripcap._https.' + hostname, (err, data) => {
        if (err) {
          rej(err);
        } else {
          let str = '';
          if (data.length > 0) {
            str = url.format({
              protocol: 'https',
              hostname: data[0].name,
              port: data[0].port
            });
          }
          res(str);
        }
      })
    });
  }

  async install(name) {
    let registry = this.parent.profile.getConfig('package-registry');
    let pkgpath = path.join(config.userPackagePath, name);
    let tarurl = '';

    let host = await this.resolveRegistry(registry);

    if (this.list[name] != null) {
      throw Error(`Package ${name} is already installed`);
    }

    await new Promise((res, rej) =>
      npm.load({
          production: true,
          host
        }, () =>
        npm.commands.view([name], function(e, data) {
          try {
            if (e != null) {
              throw e;
            }
            let pkg = data[Object.keys(data)[0]];
            if ((pkg.engines != null) && (pkg.engines.dripcap != null)) {
              let ver = pkg.engines.dripcap;
              if (semver.satisfies(config.version, ver)) {
                if ((pkg.dist != null) && (pkg.dist.tarball != null)) {
                  tarurl = pkg.dist.tarball;
                  res();
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
        })
      )
    );

    let e = await new Promise(res => fs.stat(pkgpath, e => res(e)));
    if (e == null) {
      await this.uninstall(name);
    }

    await new Promise(function(res) {
      let gunzip = zlib.createGunzip();
      let extractor = tar.Extract({
        path: pkgpath,
        strip: 1
      });
      request(tarurl).pipe(gunzip).pipe(extractor).on('finish', () => res());
    });

    await new Promise(function(res) {
      let jsonPath = path.join(pkgpath, 'package.json');
      return fs.readFile(jsonPath, function(err, data) {
        if (err) {
          throw err;
        }
        let json = JSON.parse(data);
        json['_dripcap'] = {
          name,
          registry
        };
        fs.writeFile(jsonPath, JSON.stringify(json, null, '  '), function(err) {
          if (err) {
            throw err;
          }
          res();
        });
      });
    });

    await new Promise(res => {
      return npm.commands.install(pkgpath, [], () => {
        res();
        this.updatePackageList();
      });
    });
  }

  uninstall(name) {
    let pkgpath = path.join(config.userPackagePath, name);
    return new Promise(res => {
      rmdir(pkgpath, err => {
        this.updatePackageList();
        if (err != null) {
          throw err;
        }
        res();
      });
    });
  }
}
