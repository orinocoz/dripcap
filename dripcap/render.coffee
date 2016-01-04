require('coffee-script/register')
config = require('dripcap/config')
shell = require('shell')
$ = require('jquery')

Profile = require('dripcap/profile')
prof = new Profile config.profilePath + '/default'
require('dripcap')(prof)

remote = require('remote')

dripcap.package.sub 'core:package-loaded', ->
  process.nextTick -> $('#splash').fadeOut()

dripcap.action.on 'core:new-window', ->
  remote.getGlobal('dripcap').newWindow()

dripcap.action.on 'core:close-window', ->
  remote.getCurrentWindow().close()

dripcap.action.on 'core:toggle-devtools', ->
  remote.getCurrentWindow().toggleDevTools()

dripcap.action.on 'core:open-user-directroy', ->
  shell.showItemInFolder config.profilePath

dripcap.action.on 'core:open-website', ->
  shell.openExternal 'https://github.com/dripcap/dripcap'

dripcap.action.on 'core:show-license', ->
  shell.openExternal 'https://github.com/dripcap/dripcap/blob/master/LICENSE'

dripcap.action.on 'core:quit', ->
  remote.require('app').quit()

dripcap.pubsub.sub 'core:capturing-status', (data) ->
  if (data)
    remote.getGlobal('dripcap').pushIndicator()
  else
    remote.getGlobal('dripcap').popIndicator()

dripcap.action.on 'core:stop-sessions', ->
  for s in dripcap.session.list
    s.stop()

dripcap.action.on 'core:start-sessions', ->
  if dripcap.session.list.length > 0
    for s in dripcap.session.list
      s.start()
  else
    dripcap.action.emit 'core:new-session'

remote.require('power-monitor').on 'suspend', ->
  dripcap.action.emit 'core:stop-sessions'

document.ondragover = document.ondrop = (e) ->
  e.preventDefault()
  false

$ ->
  $(window).unload ->
    for s in dripcap.session.list
      s.close()
