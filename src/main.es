import {
  app
} from 'electron';
import updater from './updater';
import {
  dialog,
  shell
} from 'electron';
import {
  BrowserWindow
} from 'electron';
import path from 'path';
import fs from 'fs';
import mkpath from 'mkpath';
import config from 'dripcap/config';
import GoldFilter from 'goldfilter';

if (process.platform === 'darwin' && process.env['DRIPCAP_UI_TEST'] != null) {
  app.dock.hide();
}

mkpath.sync(config.userPackagePath);
mkpath.sync(config.profilePath);

if (!GoldFilter.testPerm()) {
  GoldFilter.setPerm();
}

class Dripcap {
  constructor() {
    this._indicator = 0;
  }

  checkForUpdates() {
    let {
      autoUpdater
    } = require('electron');
    autoUpdater.on('error', e => {
        console.warn(e.toString());
        return setTimeout(this.checkForUpdates, 60 * 60 * 1000 * 4);
      })
      .on('checking-for-update', () => console.log('Checking for update'))
      .on('update-available', () => console.log('Update available'))
      .on('update-not-available', () => {
        console.log('Update not available');
        return setTimeout(this.checkForUpdates, 60 * 60 * 1000 * 4);
      })
      .on('update-downloaded', function() {
        let index = dialog.showMessageBox({
          message: "Updates Available",
          detail: "Do you want to install a new version now?",
          buttons: ["Restart and Install", "Not Now"]
        });

        if (index === 0) {
          return autoUpdater.quitAndInstall();
        }
      });

    return updater.createServer(function(url) {
      autoUpdater.setFeedURL(url);
      return autoUpdater.checkForUpdates();
    });
  }

  newWindow() {
    let options = {
      width: 1200,
      height: 800,
      show: false,
      titleBarStyle: 'hidden-inset'
    };

    let mainWindow = new BrowserWindow(options);
    mainWindow.loadURL(`file://${__dirname}/../render.html`);
    mainWindow.webContents.on('did-finish-load', () => {
      if (process.env['DRIPCAP_UI_TEST'] == null) {
        mainWindow.show();
      }
    });
  }
}

const dripcap = new Dripcap();

app.on('window-all-closed', () => app.quit());

app.on('ready', function() {
  if (process.platform === 'darwin') {
    dripcap.checkForUpdates();
  }
  if (process.platform === 'win32') {
    let wpcap = false;
    for (let dir of process.env.Path.split(';')) {
      try {
        fs.accessSync(path.join(dir, 'wpcap.dll'));
        wpcap = true;
        break;
      } catch (e) {}
    }
    if (!wpcap) {
      let button = dialog.showMessageBox({
        title: "WinPcap required",
        message: "Dripcap depends on WinPcap.\nPlease install WinPcap on your system.",
        buttons: ["Download WinPcap", "Quit"]
      });
      if (button === 0) {
        shell.openExternal('https://www.winpcap.org/install/');
      }
      app.quit();
    }
  }
  return dripcap.newWindow();
});
