$ = require('jquery')
riot = require('riot')
_ = require('underscore')
Component = require('dripcap/component')

class WelcomeDialog
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        dripcap.package.load('modal-dialog').then (pkg) =>
          $ =>
            n = $('<div>').addClass('container').appendTo $('body')
            @view = riot.mount(n[0], 'welcome-dialog')[0]
            @view.logo = __dirname + '/../images/dripcap.png'

            dripcap.session.on 'created', =>
              @view.hide()
              @view.update()

            dripcap.package.sub 'core:package-loaded', _.once =>
              if dripcap.profile.getConfig 'startupDialog'
                @view.show()
                @view.update()

            res()

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = WelcomeDialog
