import $ from 'jquery'
import riot from 'riot'
import { Component } from 'dripper/component'

export default class GeneralPreferencesView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
    dripcap.package.load('preferences-dialog').then((pkg) => {
      $(() => {
        let m = $('<div class="wrapper"/>')
        this._view = riot.mount(m[0], 'general-preferences-view')[0]
        pkg.root.panel.center('general', m, $('<i class="fa fa-cog"> General</i>'))

        dripcap.profile.watchConfig('theme', (id) => {
          this._view.currentTheme = id
          this._view.update()
        })

        dripcap.theme.sub('registoryUpdated', () => {
          this._view.setThemeList(dripcap.theme.registory)
          this._view.update()
        })
      })
    })
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    this._view.unmount()
    this.comp.destroy()
  }
}
