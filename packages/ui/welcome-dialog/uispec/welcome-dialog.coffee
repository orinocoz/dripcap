test "show welcome-dialog", (assert) ->
  assert.wait('[riot-tag=welcome-dialog] .modal:visible')
