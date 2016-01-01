$ = require('jquery')
riot = require('riot')
{Component} = require('dripcap/component')

class WelcomeDialog
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        dripcap.package.load('modal-dialog').then (pkg) =>
          $ =>
            n = $('<div>').addClass('container').appendTo $('body')
            @view = riot.mount(n[0], 'welcome-dialog')[0]

            dripcap.package.sub 'core:package-loaded', =>
              if dripcap.profile.getConfig 'startupDialog'
                @view.show()
                @view.update()

            res()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = WelcomeDialog
