app = require('app')
BrowserWindow = require('browser-window')
glob = require('glob')
path = require('path')
fs = require('fs')

global.done = null

app.on 'ready', ->
  total = failed = passed = 0

  mainWindow = new BrowserWindow width: 1200, height: 800, show: false
  mainWindow.webContents.loadURL 'file://' + __dirname + '/../render.html'

  p = Promise.resolve()
  uitest = process.env['DRIPCAP_UI_TEST']
  for t in glob.sync(path.join(path.resolve(uitest), '**/uispec/*.coffee'))
    do (t = t) ->
      p = p.then ->
        new Promise (res) ->
          console.log ''
          console.log '[ ' + path.basename(t) + ' ]'

          global.done = (details) ->
            total += details.total
            failed += details.failed
            passed += details.passed
            res()

          mainWindow.webContents.loadURL 'file://' + __dirname + '/../render.html'
          mainWindow.webContents.once 'dom-ready', ->
            mainWindow.webContents.executeJavaScript "require(require('path').join('#{__dirname}', '../js/uitest-init'))('#{t}');"

  p.then ->
    console.log ''
    console.log '------------------------------------------------------'
    console.log '[Summary]', 'Total: ', total, ' Failed: ', failed, ' Passed: ', passed
    console.log '------------------------------------------------------'
    fs.writeFileSync '/tmp/dripcap.test.result', "#{failed}"
    app.quit()
