QUnit.test "show session-dialog", (assert) ->
  done = assert.async()
  dripcap.package.load('session-dialog').then (pkg) ->
    dripcap.action.emit 'Core: New Session'
    handler = setInterval ->
      if $('[riot-tag=session-dialog] .modal').is(':visible')
        clearInterval handler
        assert.ok true
        done()
    , 0
