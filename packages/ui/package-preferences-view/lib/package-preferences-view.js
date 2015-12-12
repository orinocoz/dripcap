import $ from 'jquery'
import riot from 'riot'
import { Component } from 'dripper/component'

export default class PackagePreferencesView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)

    dripcap.package.load('preferences-dialog').then((pkg) => {
      $(() => {
        let m = $('<div class="wrapper"/>')
        this._view = riot.mount(m[0], 'package-preferences-view')[0]
        pkg.root.panel.center('packages', m, $('<i class="fa fa-gift"> Packages</i>'))

        dripcap.package.sub('Core: Package List Updated', (list) => {
          this._view.packageList = Object.keys(list).map((v) => list[v])
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
