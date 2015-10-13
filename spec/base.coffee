QUnit.asyncTest "show session-dialog", (assert) ->
  dripcap.package.load('session-dialog').then (pkg) ->
    dripcap.action.emit 'Core: New Session'
    setTimeout ->
      ok $('[riot-tag=session-dialog] .modal').is(':visible')
      start()
    , 1000
