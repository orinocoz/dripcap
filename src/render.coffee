if process.env['DRIPCAP_UI_TEST']?
  global.console = require('remote').getGlobal('console')

require('coffee-script/register')
config = require('./config')
global.$ = require('jquery')

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

$ ->
  $(window).unload ->
    for s in dripcap.session.list
      s.close()

  uitest = process.env['DRIPCAP_UI_TEST']
  require(uitest) if uitest?
