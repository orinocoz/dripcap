$ = require('jquery')
riot = require('riot')
{Component, Panel} = require('dripper/component')

class StatusView
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('main-view').then (pkg) =>
      $ =>
        m = $('<div/>')
        @view = riot.mount(m[0], 'status-view')[0]
        pkg.root.panel.northFixed(m)

        dripcap.pubsub.sub 'core:capturing-status', (data) =>
          @view.capturing = data
          @view.update()

        dripcap.pubsub.sub 'core:capturing-settings', (data) =>
          @view.settings = data
          @view.update()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.northFixed()
      @view.unmount()
      @comp.destroy()

module.exports = StatusView
