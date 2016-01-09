$ = require('jquery')

test "list captured packets", (assert) ->
  dripcap.action.emit 'core:start-sessions'
  assert.wait('[riot-tag=session-dialog] .modal:visible')
  .then -> assert.click('[riot-tag=session-dialog] [name=start]')
  .then -> assert.wait -> $('[riot-tag=packet-list-view] tr:not(.head)').length == 100
