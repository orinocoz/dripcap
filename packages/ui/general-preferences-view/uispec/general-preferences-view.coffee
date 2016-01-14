$ = require('jquery')

test "show general-preferences-view", (assert) ->
  dripcap.action.emit 'core:preferences'
  assert.wait('[riot-tag=preferences-dialog] .modal:visible')
  .then -> assert.click('[tab-id=general]')
  .then -> assert.wait('[riot-tag=general-preferences-view]:visible')

test "theme list", (assert) ->
  list = $('[riot-tag=general-preferences-view] [name=theme] > option').map -> $(@).text()
  assert.deepEqual list.get(), [ 'Default', 'Mocha Dark', 'Ocean Light', 'Atelier Estuary Light' ]
