path = require('path')
glob = require('glob')
rebuild = require('electron-rebuild')
npm = require('npm')
semver = require('semver')
fs = require('fs')
zlib = require('zlib')
tar = require('tar')
request = require('request')
rmdir = require('rmdir')
_ = require('underscore')

PubSub = require('./pubsub')
Package = require('./pkg')
config = require('./config')

class PackageInterface extends PubSub
  constructor: (@parent) ->
    super()
    @list = {}
    @triggerlLoaded = _.debounce =>
      @pub 'core:package-loaded'
    , 500

  load: (name) ->
    pkg = @list[name]
    throw new Error "package not found: #{name}" unless pkg?
    pkg.load()

  unload: (name) ->
    pkg = @list[name]
    throw new Error "package not found: #{name}" unless pkg?
    pkg.deactivate()

  updatePackageList: ->
    paths = glob.sync(config.packagePath + '/**/package.json')
    paths = paths.concat glob.sync(config.userPackagePath + '/**/package.json')

    for p in paths
      try
        pkg = new Package(p)

        if (loaded = @list[pkg.name])?
          if loaded.path != pkg.path
            console.warn "package name conflict: #{pkg.name}"
            continue
          else if semver.gte loaded.version, pkg.version
            continue
          else
            loaded.deactivate()
        @list[pkg.name] = pkg
      catch e
        console.warn "failed to load #{pkg.name}/package.json : #{e}"

    for k, pkg of @list
      if pkg.config.get('enabled')
        pkg.activate()
        pkg.load().then =>
          process.nextTick => @triggerlLoaded()

    @pub 'core:package-list-updated', @list

  updateTheme: (scheme) ->
    for k, pkg of @list
      if pkg.config.get('enabled')
        pkg.updateTheme scheme

  rebuild: (path) ->
    ver = config.electronVersion
    rebuild.installNodeHeaders(ver).then ->
      rebuild.rebuildNativeModules(ver, config.packagePath).then ->
        rebuild.rebuildNativeModules(ver, config.userPackagePath)

  install: (name) ->
    registry = dripcap.profile.getConfig('package-registry')
    pkgpath = path.join(config.userPackagePath, name)
    tarurl = ''

    p = Promise.resolve().then =>
      if @list[name]?
        throw Error "Package #{name} is already installed"

      new Promise (res, rej) ->
        npm.load {production: true, registry: registry}, ->
          npm.commands.view [name], (e, data) ->
            try
              throw e if e?
              pkg = data[Object.keys(data)[0]]
              if ver = pkg.engines?.dripcap
                if semver.satisfies config.version, ver
                  if tarurl = pkg.dist?.tarball
                    res()
                  else
                    throw new Error 'Tarball not found'
                else
                  throw new Error 'Dripcap version mismatch'
              else
                throw new Error 'This package is not for dripcap'
            catch e
              rej(e)

    p = p.then =>
      new Promise (res) ->
        fs.stat pkgpath, (e) -> res(e)
      .then (e) =>
        if e?
          Promise.resolve()
        else
          @uninstall(name)

    p = p.then ->
      new Promise (res) ->
        gunzip = zlib.createGunzip()
        extractor = tar.Extract({path: pkgpath, strip: 1})
        request(tarurl).pipe(gunzip).pipe(extractor).on 'finish', -> res()

    p = p.then ->
      new Promise (res) ->
        jsonPath = path.join(pkgpath, 'package.json')
        fs.readFile jsonPath, (err, data) ->
          throw err if err
          json = JSON.parse data
          json['_dripcap'] = {name: name, registry: registry}
          fs.writeFile jsonPath, JSON.stringify(json, null, '  '), (err) ->
            throw err if err
            res()

    p.then =>
      new Promise (res) =>
        npm.commands.install pkgpath, [], =>
          res()
          @updatePackageList()

  uninstall: (name) ->
    pkgpath = path.join(config.userPackagePath, name)
    new Promise (res) ->
      rmdir pkgpath, (err) ->
        throw err if err?
        res()

module.exports = PackageInterface
