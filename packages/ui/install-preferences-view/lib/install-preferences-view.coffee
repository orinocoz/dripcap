$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class InstallPreferencesView
  activate: ->

    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('preferences-dialog').then (pkg) =>
      $ =>
        m = $('<div class="wrapper"/>')
        @_view = riot.mount(m[0], 'install-preferences-view')[0]
        pkg.root.panel.center('install', m, $('<i class="fa fa-cloud-download"> Install</i>'))

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @_view.unmount()
    @comp.destroy()

module.exports = InstallPreferencesView
