fs = require('fs')
path = require('path')
CSON = require('cson')
mkpath = require('mkpath')

class Profile
  constructor: (@path) ->
    @configPath = path.join @path, '/config.cson'
    @packagePath = path.join @path, '/package.cson'
    @layoutPath = path.join @path, '/layout.cson'
    @initPath = path.join @path, '/init.coffee'

    try
      @config = CSON.parse fs.readFileSync @configPath
    catch
      @config = {}

    try
      @package = CSON.parse fs.readFileSync @packagePath
    catch e
      console.log e
      @package = {}

    try
      @layout = CSON.parse fs.readFileSync @layoutPath
    catch
      @layout = {}

  init: ->
    try
      require(@initPath)
    catch e
      console.warn e

  save: ->
    mkpath.sync(@path)
    fs.writeFileSync @configPath, CSON.stringify @config
    fs.writeFileSync @packagePath, CSON.stringify @package
    fs.writeFileSync @layoutPath, CSON.stringify @layout

module.exports = Profile
