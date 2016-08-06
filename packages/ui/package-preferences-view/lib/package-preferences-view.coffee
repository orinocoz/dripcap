$ = require('jquery')
riot = require('riot')
Component = require('dripcap/component')

class PackagePreferencesView
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('preferences-dialog').then (pkg) =>
        $ =>
          m = $('<div class="wrapper"/>')
          @_view = riot.mount(m[0], 'package-preferences-view')[0]
          pkg.root.panel.center('package', m, $('<i class="fa fa-gift"> Packages</i>'))

          dripcap.package.sub 'core:package-list-updated', (list) =>
            @_view.packageList = Object.keys(list).map (v) -> list[v]
            @_view.update()
      res()

  deactivate: ->
    @_view.unmount()
    @comp.destroy()

module.exports = PackagePreferencesView
