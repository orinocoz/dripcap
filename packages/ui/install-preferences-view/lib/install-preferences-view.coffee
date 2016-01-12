$ = require('jquery')
riot = require('riot')
Component = require('dripcap/component')

class InstallPreferencesView
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('preferences-dialog').then (pkg) =>
        $ =>
          m = $('<div class="wrapper"/>')
          @_view = riot.mount(m[0], 'install-preferences-view')[0]
          pkg.root.panel.center('install', m, $('<i class="fa fa-cloud-download"> Install</i>'))
      res()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @_view.unmount()
    @comp.destroy()

module.exports = InstallPreferencesView
