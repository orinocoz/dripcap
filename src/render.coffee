require('coffee-script/register')
config = require('./config')
shell = require('shell')
global.$ = require('jquery')
global.riot = require('riot')

Profile = require('./profile')
prof = new Profile config.profilePath + '/default'
require('./dripcap').init prof

remote = require('remote')

unless process.env['DRIPCAP_UI_TEST']?
  remote.getCurrentWindow().show()

dripcap.action.on 'Core: New Window', ->
  remote.getGlobal('dripcap').newWindow()

dripcap.action.on 'Core: Close Window', ->
  remote.getCurrentWindow().close()

dripcap.action.on 'Core: Toggle DevTools', ->
  remote.getCurrentWindow().toggleDevTools()

dripcap.action.on 'Core: Open Dripcap Website', ->
  shell.openExternal 'https://github.com/dripcap/dripcap'

dripcap.action.on 'Core: Show License', ->
  shell.openExternal 'https://github.com/dripcap/dripcap/blob/master/LICENSE'

dripcap.action.on 'Core: Quit', ->
  remote.require('app').quit()

dripcap.pubsub.sub 'Core: Capturing Status', (data) ->
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

remote.require('power-monitor').on 'suspend', ->
  dripcap.action.emit 'Core: Stop Sessions'

$ ->
  $(window).unload ->
    for s in dripcap.session.list
      s.close()
