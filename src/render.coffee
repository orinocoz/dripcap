require('coffee-script/register')
config = require('./config')
global.$ = require('jquery')
global.riot = require('riot')

Profile = require('./profile')
prof = new Profile config.profilePath + '/default'
require('./dripcap').init prof

remote = require('remote')
remote.getCurrentWindow().show()

dripcap.action.on 'Core: New Window', ->
  remote.getGlobal('dripcap').newWindow()

dripcap.action.on 'Core: Close Window', ->
  remote.getCurrentWindow().close()

dripcap.action.on 'Core: Toggle DevTools', ->
  remote.getCurrentWindow().toggleDevTools()

dripcap.action.on 'Core: Quit', ->
  remote.getGlobal('dripcap').quit()

dripcap.pubsub.sub 'Core: Capturing Status Updated', (data) ->
  if (data)
    remote.getGlobal('dripcap').pushIndicator()
  else
    remote.getGlobal('dripcap').popIndicator()

dripcap.action.on 'Core: Stop Sessions', ->
  for s in dripcap.session.list
    s.stop()

dripcap.action.on 'Core: Start Sessions', ->
  if dripcap.session.list.length > 0
    for s in dripcap.session.list
      s.start()
  else
    dripcap.action.emit 'Core: New Session'

$ ->
  $(window).unload ->
    for s in dripcap.session.list
      s.close()
