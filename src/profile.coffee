fs = require('fs')
path = require('path')
CSON = require('cson')
mkpath = require('mkpath')

class Profile
  constructor: (@path) ->
    @_configPath = path.join @path, '/config.cson'
    @_packagePath = path.join @path, '/package.cson'
    @_layoutPath = path.join @path, '/layout.cson'
    @_initPath = path.join @path, '/init.coffee'

    try
      @config = CSON.parse fs.readFileSync @_configPath
    catch e
      console.warn e
      @config = {}

    try
      @package = CSON.parse fs.readFileSync @_packagePath
    catch e
      console.warn e
      @package = {}

    try
      @layout = CSON.parse fs.readFileSync @_layoutPath
    catch e
      console.warn e
      @layout = {}

  init: ->
    try
      require(@_initPath)
    catch e
      unless e.code == "MODULE_NOT_FOUND"
        console.warn e

  save: ->
    mkpath.sync(@path)
    fs.writeFileSync @_configPath, CSON.stringify @config
    fs.writeFileSync @_packagePath, CSON.stringify @package
    fs.writeFileSync @_layoutPath, CSON.stringify @layout

module.exports = Profile
