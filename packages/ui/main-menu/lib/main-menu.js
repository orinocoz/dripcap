import $ from 'jquery'
import fs from 'fs'
import remote from 'remote'
const Menu = remote.require('menu')
const MenuItem = remote.require('menu-item')

export default class MainMenu {
  activate() {

    let action = (name) => {
      return () => {
        return dripcap.action.emit(name)
      }
    }

    this.menu = (menu, e) => {
      let file = new Menu
      file.append(new MenuItem({label: 'New Window', accelerator: 'CmdOrCtrl+Shift+N', click: action('Core: New Window')}))
      file.append(new MenuItem({label: 'Close Window', accelerator: 'CmdOrCtrl+Shift+W', click: action('Core: Close Window')}))
      file.append(new MenuItem({type: 'separator'}))
      file.append(new MenuItem({label: 'Quit', accelerator: 'CmdOrCtrl+Q', click: action('Core: Quit')}))

      let edit = new Menu
      if (process.platform === 'darwin') {
        edit.append(new MenuItem({label: 'Cut', accelerator: 'Cmd+X', selector: 'cut:'}))
        edit.append(new MenuItem({label: 'Copy', accelerator: 'Cmd+C', selector: 'copy:'}))
        edit.append(new MenuItem({label: 'Paste', accelerator: 'Cmd+V', selector: 'paste:'}))
        edit.append(new MenuItem({label: 'Select All', accelerator: 'Cmd+A', selector: 'selectAll:'}))
      } else {
        let contents = remote.getCurrentWebContents()
        edit.append(new MenuItem({label: 'Cut', accelerator: 'Ctrl+X', click: () => contents.cut()}))
        edit.append(new MenuItem({label: 'Copy', accelerator: 'Ctrl+C', click: () => contents.copy()}))
        edit.append(new MenuItem({label: 'Paste', accelerator: 'Ctrl+V', click: () => contents.paste()}))
        edit.append(new MenuItem({label: 'Select All', accelerator: 'Ctrl+A', click: () => contents.selectAll()}))
      }
      edit.append(new MenuItem({type: 'separator'}))
      edit.append(new MenuItem({label: 'Preferences', accelerator: 'CmdOrCtrl+,', click: action('Core: Preferences')}))

      let capturing = dripcap.pubsub.get('Core: Capturing Status')
      if (capturing == null) capturing = false
      let session = new Menu
      session.append(new MenuItem({label: 'New Session', accelerator: 'CmdOrCtrl+N', click: action('Core: New Session')}))
      session.append(new MenuItem({type: 'separator'}))
      session.append(new MenuItem({label: 'Start', enabled: !capturing, click: action('Core: Start Sessions')}))
      session.append(new MenuItem({label: 'Stop', enabled: capturing, click: action('Core: Stop Sessions')}))

      let developer = new Menu
      developer.append(new MenuItem({label: 'Toggle DevTools', accelerator: 'CmdOrCtrl+Shift+I', click: action('Core: Toggle DevTools')}))
      developer.append(new MenuItem({label: 'Open User Directory', click: action('Core: Open User Directory')}))

      let help = new Menu
      help.append(new MenuItem({label: 'Open Website', click: action('Core: Open Dripcap Website')}))
      help.append(new MenuItem({label: 'Show License', click: action('Core: Show License')}))
      help.append(new MenuItem({type: 'separator'}))
      help.append(new MenuItem({label: 'Version ' + JSON.parse(fs.readFileSync(__dirname + '/../../../../package.json')).version, enabled: false}))

      menu.append(new MenuItem({label: 'File', submenu: file, type: 'submenu'}))
      menu.append(new MenuItem({label: 'Edit', submenu: edit, type: 'submenu'}))
      menu.append(new MenuItem({label: 'Session', submenu: session, type: 'submenu'}))
      menu.append(new MenuItem({label: 'Developer', submenu: developer, type: 'submenu'}))
      return menu
    }

    this.helpMenu = (menu, e) => {
      let help = new Menu
      help.append(new MenuItem({label: 'Open Website', click: action('Core: Open Dripcap Website')}))
      help.append(new MenuItem({label: 'Show License', click: action('Core: Show License')}))
      help.append(new MenuItem({type: 'separator'}))
      help.append(new MenuItem({label: 'Version ' + JSON.parse(fs.readFileSync(__dirname + '/../../../../package.json')).version, enabled: false}))

      menu.append(new MenuItem({label: 'Help', submenu: help, type: 'submenu', role: 'help'}))
      return menu
    }

    dripcap.menu.register('MainMenu: MainMenu', this.menu)
    dripcap.menu.register('MainMenu: MainMenu', this.helpMenu, -10)

    dripcap.theme.sub('registoryUpdated', () => dripcap.menu.updateMainMenu())
    dripcap.pubsub.sub('Core: Capturing Status', () => dripcap.menu.updateMainMenu())

  }

  deactivate() {
    dripcap.menu.unregister('MainMenu: MainMenu', this.menu)
    dripcap.menu.unregister('MainMenu: MainMenu', this.helpMenu)
  }
}
