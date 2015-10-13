QUnit.asyncTest "show session-dialog", (assert) ->
  dripcap.package.load('session-dialog').then (pkg) ->
    dripcap.action.emit 'Core: New Session'
    handler = setInterval ->
      if $('[riot-tag=session-dialog] .modal').is(':visible')
        clearInterval handler
        ok true
        start()
    , 0
