$ = require('jquery')
fs = require('fs')

class MainMenu
  activate: ->
    template = [
      label: 'File'
      submenu: [
        label: 'New Window'
        accelerator: 'Ctrl+Shift+N'
        action: 'Core: New Window'
      ,
        label: 'Close Window'
        accelerator: 'Ctrl+Shift+W'
        action: 'Core: Close Window'
      ,
        type: 'separator'
      ,
        label: 'Quit'
        accelerator: 'Ctrl+Q'
        action: 'Core: Quit'
      ]
    ,
      label: 'Session'
      submenu: [
        label: 'New Session'
        accelerator: 'Ctrl+N'
        action: 'Core: New Session'
      ,
        type: 'separator'
      ,
        label: 'Start'
        action: 'Core: Start Sessions'
      ,
        label: 'Stop'
        action: 'Core: Stop Sessions'
      ]
    ,
      label: 'Theme'
      submenu: [
        label: '(no theme)'
        enabled: false
      ]
    ,
      label: 'Developer'
      submenu: [
        label: 'Toggle DevTools'
        accelerator: 'Ctrl+Shift+I'
        action: 'Core: Toggle DevTools'
      ]
    ,
      label: 'Help'
      submenu: [
        label: 'Open Website'
        action: 'Core: Open dripcap Website'
      ,
        label: 'Show License'
        action: 'Core: Show License'
      ,
        type: 'separator'
      ,
        label: 'Version ' + JSON.parse(fs.readFileSync(__dirname + '/../../../../package.json')).version
        enabled: false
      ]
    ]

    for t in template
      dripcap.menu.add [], t

    dripcap.menu.get(['Session', 'Start']).enabled = false
    dripcap.menu.get(['Session', 'Stop']).enabled = false

    selectedScheme = 'default'
    dripcap.theme.sub 'updateRegistory', ->
      for k, v of dripcap.theme.registory
        do (k = k, v = v) ->
          dripcap.menu.add ['Theme'],
            label: v.name
            type: 'radio'
            checked: selectedScheme == k
            click: ->
              selectedScheme = k
              dripcap.theme.scheme = v
      dripcap.menu.remove(['Theme', '(no theme)'])

    dripcap.pubsub.sub 'Core: Capturing Status Updated', (data) ->
      if (data)
        dripcap.menu.get(['Session', 'Start']).enabled = false
        dripcap.menu.get(['Session', 'Stop']).enabled = true
      else
        dripcap.menu.get(['Session', 'Start']).enabled = true
        dripcap.menu.get(['Session', 'Stop']).enabled = false

  deactivate: ->

module.exports = MainMenu
