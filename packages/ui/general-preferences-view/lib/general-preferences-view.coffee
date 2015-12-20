$ = require('jquery')
riot = require('riot')
{Component} = require('dripper/component')

class GeneralPreferencesView
  activate: ->

    @comp = new Component "#{__dirname}/../tag/*.tag"
    dripcap.package.load('preferences-dialog').then (pkg) =>
      $ =>
        m = $('<div class="wrapper"/>')
        @_view = riot.mount(m[0], 'general-preferences-view')[0]
        pkg.root.panel.center('general', m, $('<i class="fa fa-cog"> General</i>'))

        dripcap.theme.sub 'registoryUpdated', =>
          @_view.setThemeList(dripcap.theme.registory)
          @_view.update()

        dripcap.profile.watchConfig 'theme', (id) =>
          @_view.currentTheme = id
          @_view.update()

        dripcap.profile.watchConfig 'snaplen', (len) =>
          @_view.currentSnaplen = len
          @_view.update()

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @_view.unmount()
    @comp.destroy()

module.exports = GeneralPreferencesView
