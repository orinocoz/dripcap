fs = require('fs')
path = require('path')
CSON = require('cson')
mkpath = require('mkpath')
_ = require('underscore')

class Category
  constructor: (@_name, @_path, defaultValue = {}) ->
    try
      @_data = CSON.parse fs.readFileSync @_path
    catch e
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
    @_handlers[key] ?= []
    @_handlers[key] = _.without(@_handlers[key], handler)

  _save: ->
    fs.writeFileSync @_path, CSON.stringify @_data

class Profile
  constructor: (@path) ->
    mkpath.sync(@path)
    @_initPath = path.join @path, '/init.coffee'

    @_config = new Category 'config', path.join(@path, '/config.cson'),
      snaplen: 1600
      theme: "default"
      
    @_package = new Category 'package', path.join(@path,'/package.cson')
    @_layout = new Category 'layout', path.join(@path,'/layout.cson')

  getConfig:     (key) -> @_config.get key
  setConfig:     (key, value) -> @_config.set key, value
  watchConfig:   (key, handler) -> @_config.watch key, handler
  unwatchConfig: (key, handler) -> @_config.unwatch key, handler

  getPackage:     (key) -> @_package.get key
  setPackage:     (key, value) -> @_package.set key, value
  watchPackage:   (key, handler) -> @_package.watch key, handler
  unwatchPackage: (key, handler) -> @_package.unwatch key, handler

  getLayout:     (key) -> @_layout.get key
  setLayout:     (key, value) -> @_layout.set key, value
  watchLayout:   (key, handler) -> @_layout.watch key, handler
  unwatchLayout: (key, handler) -> @_layout.unwatch key, handler

  init: ->
    try
      require(@_initPath)
    catch e
      unless e.code == "MODULE_NOT_FOUND"
        console.warn e

module.exports = Profile
