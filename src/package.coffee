fs = require('fs')
path = require('path')
_ = require('underscore')

class Package
  constructor: (jsonPath) ->
    @path = path.dirname(jsonPath)

    info = JSON.parse(fs.readFileSync(jsonPath))

    if info.name?
      @name = info.name
    else
      throw new Error 'package name required'

    if info.main?
      @main = info.main
    else
      throw new Error 'package main required'

    @version = info.version
    @version ?= '0.0.1'

    @config =
      enabled: true

    @_promise =
      new Promise (resolve) =>
        @_resolve = resolve
      .then =>
        new Promise (resolve, reject) =>
          req = path.resolve(@path, @main)
          try
            klass = require(req)
            @root = new klass()
            @root.activate()
            @updateTheme(dripcap.theme.scheme)

          catch e
            reject(e)
            return

          resolve(@)

  load: ->
    @_promise

  activate: ->
    @_resolve()

  updateTheme: (theme) ->
    @load().then =>
      if @root? && @root.updateTheme?
        @root.updateTheme theme

  deactivate: ->
    @load().then =>
      new Promise (resolve, reject) =>
        try
          @root.deactivate()
          @root = null
          for key of require.cache
            if key.startsWith(@path)
              delete require.cache[key]
        catch e
          reject(e)
          return
        resolve(@)

module.exports = Package
