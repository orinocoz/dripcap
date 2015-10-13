require('coffee-script/register')
app = require('app')
BrowserWindow = require('browser-window')
mkpath = require('mkpath')
glob = require('glob')
path = require('path')
fs = require('fs')
ipc = require('ipc')
config = require('./config')
require('crash-reporter').start(config.crashReporter)

class Dripcap
  constructor: ->

  newWindow: ->
    options =
      width: 1200
      height: 800
      show: false
      'title-bar-style': 'hidden-inset'

    mainWindow = new BrowserWindow options
    mainWindow.loadUrl 'file://' + __dirname + '/../render.html'

  quit: ->
    app.quit()

if process.env['DRIPCAP_UI_TEST']?
  app.on 'ready', ->
    mkpath.sync(config.userPackagePath)
    mkpath.sync(config.profilePath)

    p = Promise.resolve()

    total = 0
    failed = 0
    passed = 0
    ipc.on 'test-done', (event, details) ->
      console.log( 'Total: ', details.total, ' Failed: ', details.failed, ' Passed: ', details.passed, ' Runtime: ', details.runtime )
      total += details.total
      failed += details.failed
      passed += details.passed

    uitest = process.env['DRIPCAP_UI_TEST']
    for t in glob.sync(path.join(uitest, '/*.coffee'))
      do (t = t) ->
        p = p.then ->
          new Promise (res) ->
            mainWindow = new BrowserWindow width: 1200, height: 800
            mainWindow.loadUrl 'file://' + __dirname + '/../render.html'
            mainWindow.webContents.on 'did-finish-load', ->
              test = "
                ipc = require('ipc');
                global.console = require('remote').getGlobal('console');

                $(function(){
                  $.getScript('http://code.jquery.com/qunit/qunit-1.19.0.js', function() {
                    QUnit.log(function( details ) {
                      if (details.result) {
                        console.log(details.name + ': ', details.message);
                      } else {
                        console.log(details.name + ':', 'expected:', details.expected, 'actual:', details.actual, details.source);
                      }
                    });
                    QUnit.done(function( details ) {
                      ipc.send('test-done', details);
                      require('remote').getCurrentWindow().close();
                    });
                    require('#{t}');
                  });
                });
              "
              mainWindow.webContents.executeJavaScript test
            mainWindow.on 'close', -> res()

    p.then ->
      fs.writeFileSync '/tmp/dripcap.test.result', "#{failed}"
      app.quit()

else
  app.on 'window-all-closed', ->
    app.quit()

  app.on 'ready', ->
    global.dripcap = new Dripcap()
    mkpath.sync(config.userPackagePath)
    mkpath.sync(config.profilePath)
    dripcap.newWindow()
