app = require('app')
BrowserWindow = require('browser-window')
glob = require('glob')
path = require('path')
fs = require('fs')
ipc = require('electron').ipcMain

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
          mainWindow = new BrowserWindow width: 1200, height: 800, show: false
          mainWindow.loadURL 'file://' + __dirname + '/../render.html'
          mainWindow.webContents.on 'did-finish-load', ->
            mainWindow.webContents.executeJavaScript "require(require('path').join(location.pathname, '../js/uitest-init'))('#{t}');"
          mainWindow.on 'close', -> res()

  p.then ->
    console.log '[Summary]', 'Total: ', total, ' Failed: ', failed, ' Passed: ', passed
    fs.writeFileSync '/tmp/dripcap.test.result', "#{failed}"
    app.quit()
