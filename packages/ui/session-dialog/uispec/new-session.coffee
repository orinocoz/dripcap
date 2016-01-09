$ = require('jquery')

test "show session-dialog", (assert) ->
  dripcap.action.emit 'core:start-sessions'
  assert.wait('[riot-tag=session-dialog] .modal:visible')

test "interface list", (assert) ->
  list = $('[riot-tag=session-dialog] [name=interface] > option').map -> $(@).text()
  assert.deepEqual list.get(), [ 'eth0', 'nflog', 'nfqueue', 'any', 'lo' ], 'okay'

test "cancel dialog", (assert) ->
  assert.click '[riot-tag=session-dialog] .modal'
  .then -> assert.wait('[riot-tag=session-dialog] .modal:not(:visible)')
