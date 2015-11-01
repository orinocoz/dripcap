$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class SessionDialog
  activate: ->

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
    dripcap.keybind.unbind 'enter', '[riot-tag=session-dialog] .content'
    @view.unmount()
    @comp.destroy()

module.exports = SessionDialog
