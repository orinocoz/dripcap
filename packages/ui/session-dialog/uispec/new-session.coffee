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

QUnit.test "interface list", (assert) ->
  list = $('[riot-tag=session-dialog] [name=interface] > option').map -> $(@).text()
  assert.deepEqual list.get(), [ 'eth0', 'nflog', 'nfqueue', 'any', 'lo' ]

QUnit.test "cancel dialog", (assert) ->
  $('[riot-tag=session-dialog] .modal').click()
  assert.ok !$('[riot-tag=session-dialog] .modal').is(':visible')
