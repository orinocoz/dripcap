$ = require('jquery')
_ = require('underscore')
remote = require('electron').remote

hadlers = []

global.console = remote.getGlobal('console')

global.test = (name, handler) ->
  hadlers.push
    name: name
    handler: handler

class Assert
  wait: (value) ->
    new Promise (resolve) ->
      handler = setInterval ->
        switch
          when _.isFunction value
            if res = value()
              clearInterval handler
              resolve(res)
          when _.isString value
            elem = $(value)
            if elem.length > 0
              clearInterval handler
              resolve(elem)
      , 10

  click: (selector) ->
    Promise.resolve().then ->
      $(selector).each (i, elem) -> elem.click()

  true: (value) ->
    Promise.resolve().then ->
      throw "actual: #{a} expects: #{b}" unless _.isBoolean(value) && value

  ok: -> Promise.resolve()

  deepEqual: (a, b) ->
    Promise.resolve().then ->
      throw "actual: #{a} expects: #{b}" unless _.isEqual(a, b)

module.exports = (file) ->
  dripcap.package.sub 'core:package-loaded', ->
    require file

    details =
      total: 0
      failed: 0
      passed: 0

    timeout = 60000

    promise = Promise.resolve()
    for h in hadlers
      do (h) ->
        promise = promise.then ->
          details.total++
          new Promise (resolve) ->
            timeout = setTimeout ->
              console.warn " ✘ #{h.name} TIMEOUT"
              details.failed++
              resolve()
            , timeout

            h.handler(new Assert).then ->
              clearTimeout timeout
              console.log " ✔ #{h.name}"
              details.passed++
              resolve()
            .catch (err) ->
              clearTimeout timeout
              console.warn " ✘ #{h.name} #{err}"
              details.failed++
              resolve()

    promise.then ->
      remote.getGlobal('done')(details)
