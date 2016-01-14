test "show install-preferences-view", (assert) ->
  dripcap.action.emit 'core:preferences'
  assert.wait('[riot-tag=preferences-dialog] .modal:visible')
  .then -> assert.click('[tab-id=install]')
  .then -> assert.wait('[riot-tag=install-preferences-view]:visible')
