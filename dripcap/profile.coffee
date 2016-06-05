fs = require('fs')
path = require('path')
CSON = require('cson')
mkpath = require('mkpath')
_ = require('underscore')

class Category
  constructor: (@_path, defaultValue = {}) ->
    try
      @_data = CSON.parse fs.readFileSync @_path
    catch e
      if e.code != 'ENOENT'
        console.warn e
      @_data = defaultValue
      @_save()

    @_data = _.extend defaultValue, @_data
    @_handlers = {}

  get: (key) -> @_data[key]

  set: (key, value) ->
    unless _.isEqual value, @_data[key]
      @_data[key] = value
      if @_handlers[key]?
        for h in @_handlers[key]
          h(value)
      @_save()

  watch: (key, handler) ->
    @_handlers[key] ?= []
    @_handlers[key].push handler
    _.uniq @_handlers[key]

  unwatch: (key, handler) ->
    if @_handlers[key]?
      @_handlers[key] = _.without(@_handlers[key], handler)

  _save: ->
    fs.writeFileSync @_path, CSON.stringify @_data

class Profile
  constructor: (@path) ->
    @_packagePath = path.join @path, 'packages'
    mkpath.sync(@path)
    mkpath.sync(@_packagePath)

    @_initPath = path.join @path, 'init.coffee'

    @_config = new Category path.join(@path, 'config.cson'),
      snaplen: 1600
      theme: 'default'
      "package-registry": 'https://registry.npmjs.org/'
      startupDialog: true

    @_packages = {}

    try
      @_keyMap = CSON.parse fs.readFileSync path.join(@path, 'keymap.cson')
    catch e
      if e.code != 'ENOENT'
        console.warn e
      @_keyMap = {}

  getConfig:     (key) -> @_config.get key
  setConfig:     (key, value) -> @_config.set key, value
  watchConfig:   (key, handler) -> @_config.watch key, handler
  unwatchConfig: (key, handler) -> @_config.unwatch key, handler

  getKeymap: -> @_keyMap

  getPackageConfig: (name) ->
    if !@_packages[name]?
      @_packages[name] = new Category path.join(@_packagePath, "#{name}.cson"),
        enabled: true
    @_packages[name]

  init: ->
    try
      require(@_initPath)
    catch e
      unless e.code == "MODULE_NOT_FOUND"
        console.warn e

module.exports = Profile
