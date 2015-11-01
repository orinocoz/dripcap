$ = require('jquery')
riot = require('riot')
{Component, Panel} = require('dripper/component')

class StatusView
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('main-view').then (pkg) =>
      $ =>
        panel = $('#main-view').children('.panel.root').detach()
        panel2 = new Panel
        panel2.center panel
        $('#main-view').append panel2.root

        m = $('<div/>')
        @view = riot.mount(m[0], 'status-view')[0]
        panel2.topFixed(m)

        dripcap.pubsub.sub 'Core: Capturing Status Updated', (data) =>
          @view.capturing = data
          @view.update()

        dripcap.pubsub.sub 'Core:updateCapturingSettings', (data) =>
          @view.settings = data
          @view.update()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @view.unmount()
    @comp.destroy()

module.exports = StatusView
