import $ from 'jquery'
import riot from 'riot'
import { Component } from 'dripper/component'

export default class PacketFilterView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
    dripcap.package.load('main-view').then((pkg) => {
      $(() => {
        let m = $('<div/>')
        this.view = riot.mount(m[0], 'packet-filter-view')[0]
        pkg.root.panel.leftSouthFixed(m)
      })
    })
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.package.load('main-view').then((pkg) => {
      pkg.root.panel.leftSouthFixed()
      this.view.unmount()
      this.comp.destroy()
    })
  }
}
