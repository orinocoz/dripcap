$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')
remote = require('remote')
MenuItem = remote.require('menu-item')

class SessionDialog
  activate: ->
    @captureMenu = (menu, e) ->
      action = (name) -> -> dripcap.action.emit name
      capturing = dripcap.pubsub.get('Core: Capturing Status') ? false
      console.log dripcap.pubsub.get('Core: Capturing Status')
      menu.append new MenuItem label: 'New Session', accelerator: 'CmdOrCtrl+N', click: action 'Core: New Session'
      menu.append new MenuItem type: 'separator'
      menu.append new MenuItem label: 'Start', enabled: !capturing, click: action 'Core: Start Sessions'
      menu.append new MenuItem label: 'Stop', enabled: capturing, click: action 'Core: Stop Sessions'
      menu

    dripcap.menu.registerMain 'Capture', @captureMenu
    dripcap.pubsub.sub 'Core: Capturing Status', ->
      dripcap.menu.updateMainMenu()

    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('main-view').then (pkg) =>
      dripcap.package.load('modal-dialog').then (pkg) =>
        $ =>
          n = $('<div>').addClass('container').appendTo $('body')
          @view = riot.mount(n[0], 'session-dialog')[0]

          dripcap.keybind.bind 'enter', '[riot-tag=session-dialog] .content', =>
            $(@view.tags['modal-dialog'].start).click()

          dripcap.getInterfaceList().then (list) =>
            @view.setInterfaceList(list)
            @view.update()

          dripcap.action.on 'Core: New Session', =>
            dripcap.getInterfaceList().then (list) =>
              @view.setInterfaceList(list)
              @view.show()
              @view.update()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.menu.unregisterMain 'Capture', @captureMenu
    dripcap.keybind.unbind 'enter', '[riot-tag=session-dialog] .content'
    @view.unmount()
    @comp.destroy()

module.exports = SessionDialog
