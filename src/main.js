require('babel-core/register')({ignore: /.+\/node_modules\/(?!dripper).+\/.+.js/})
import 'coffee-script/register'
import app from 'app'
import BrowserWindow from 'browser-window'
import mkpath from 'mkpath'
import config from './config'
require('crash-reporter').start(config.crashReporter)

mkpath.sync(config.userPackagePath)
mkpath.sync(config.profilePath)

class Dripcap {
  constructor() {
    this._indicator = 0
  }

  newWindow() {
    const options = {
      width: 1200,
      height: 800,
      show: false,
      'title-bar-style': 'hidden-inset'
    }

    let mainWindow = new BrowserWindow(options)
    mainWindow.loadURL ('file://' + __dirname + '/../render.html')

    if (process.platform === 'darwin') {
      let webContents = mainWindow.webContents
      mainWindow.on('enter-full-screen', () => {
        webContents.executeJavaScript("$('#main-view').css('top', '32px')")
      })
      mainWindow.on('leave-full-screen', () => {
        webContents.executeJavaScript("$('#main-view').css('top', '0')")
      })
    }
  }

  pushIndicator() {
    this._indicator++
    if (this._indicator === 1) {
      if (process.platform === 'darwin') {
        this._indicatorInterval = setInterval(() => {
          switch (this._indicator) {
            case 0:
              app.dock.setBadge(" ● ○ ○ ")
              break
            case 1:
              app.dock.setBadge(" ○ ● ○ ")
              break
            case 2:
              app.dock.setBadge(" ○ ○ ● ")
              break
          }
          this._indicator = (this._indicator + 1) % 3
        }, 500)
      }
    }
  }

  popIndicator() {
    if (this._indicator > 0) {
      this._indicator--
    }
    if (this._indicator <= 0) {
      if (process.platform === 'darwin') {
        clearInterval(this._indicatorInterval)
        app.dock.setBadge("")
      }
    }
  }
}

global.dripcap = new Dripcap()

app.on('window-all-closed', () => app.quit())
app.on('ready', () => dripcap.newWindow())
