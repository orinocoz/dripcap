app = require('app')
BrowserWindow = require('browser-window')
glob = require('glob')
path = require('path')
fs = require('fs')
ipc = require('ipc')

app.on 'ready', ->
  total = 0
  failed = 0
  passed = 0
  ipc.on 'test-done', (event, details) ->
    console.log 'Total: ', details.total, ' Failed: ', details.failed, ' Passed: ', details.passed, ' Runtime: ', details.runtime
    total += details.total
    failed += details.failed
    passed += details.passed

  p = Promise.resolve()
  uitest = process.env['DRIPCAP_UI_TEST']
  for t in glob.sync(path.join(uitest, '/**/uispec/*.coffee'))
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
                  QUnit.config.testTimeout = 10000;
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
                  global.wait = function(assert, func) {
                    var done = assert.async();
                    var handler;
                    return handler = setInterval(function() {
                      if (func()) {
                        clearInterval(handler);
                        assert.ok(true);
                        return done();
                      }
                    }, 0);
                  };
                  require('#{t}');
                });
              });
            "
            mainWindow.webContents.executeJavaScript test
          mainWindow.on 'close', -> res()

  p.then ->
    console.log '[Summary]', 'Total: ', total, ' Failed: ', failed, ' Passed: ', passed
    fs.writeFileSync '/tmp/dripcap.test.result', "#{failed}"
    app.quit()
