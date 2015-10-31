ipc = require('ipc')
global.console = require('remote').getGlobal('console')

module.exports = (file) ->
  $ ->
    $.getScript 'http://code.jquery.com/qunit/qunit-1.19.0.js', ->
      QUnit.config.testTimeout = 10000

      QUnit.log (details) ->
        if details.result
          console.log details.name + ': ', details.message
        else
          console.log details.name + ':', 'expected:', details.expected, 'actual:', details.actual, details.source

      QUnit.done (details) ->
        ipc.send 'test-done', details
        require('remote').getCurrentWindow().close()

      global.wait = (assert, func) ->
        done = assert.async()
        handler = undefined
        handler = setInterval((->
          if func()
            clearInterval handler
            assert.ok true
            done()
        ), 0)

      require "#{file}"
