test "show package-preferences-view", (assert) ->
  dripcap.action.emit 'core:preferences'
  assert.wait('[riot-tag=preferences-dialog] .modal:visible')
  .then -> assert.click('[tab-id=package]')
  .then -> assert.wait('[riot-tag=package-preferences-view]:visible')
