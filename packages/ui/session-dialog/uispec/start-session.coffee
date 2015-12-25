QUnit.test "show session-dialog", (assert) ->
  dripcap.package.load('session-dialog').then (pkg) ->
    dripcap.action.emit 'core:start-sessions'
    wait assert, -> $('[riot-tag=session-dialog] .modal').is(':visible')
