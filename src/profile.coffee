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

  get: (key) -> @_data[key]

  set: (key, value) ->
    unless _.isEqual value, @_data[key]
      @_data[key] = value
      @_save()

  _save: ->
    fs.writeFileSync @_path, CSON.stringify @_data

class Profile
  constructor: (@path) ->
    mkpath.sync(@path)
    @_initPath = path.join @path, '/init.coffee'

    @_config = new Category 'config', path.join(@path, '/config.cson')
    @_package = new Category 'package', path.join(@path,'/package.cson')
    @_layout = new Category 'layout', path.join(@path,'/layout.cson')

  getConfig:  (key) -> @_config.get key
  setConfig:  (key, value) -> @_config.set key, value
  getPackage: (key) -> @_package.get key
  setPackage: (key, value) -> @_package.set key, value
  getLayout:  (key) -> @_layout.get key
  setLayout:  (key, value) -> @_layout.set key, value

  init: ->
    try
      require(@_initPath)
    catch e
      unless e.code == "MODULE_NOT_FOUND"
        console.warn e

module.exports = Profile
