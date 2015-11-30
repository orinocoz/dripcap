import $ from 'jquery'
import riot from 'riot'
import { Component, Panel } from 'dripper/component'

export default class StatusView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
    dripcap.package.load('main-view').then((pkg) => {
      $(() => {
        let m = $('<div/>')
        this.view = riot.mount(m[0], 'status-view')[0]
        pkg.root.panel.northFixed(m)

        dripcap.pubsub.sub('Core: Capturing Status', (data) => {
          this.view.capturing = data
          this.view.update()
        })

        dripcap.pubsub.sub('Core: Capturing Settings', (data) => {
          this.view.settings = data
          this.view.update()
        })
      })
    })
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.package.load('main-view').then((pkg) => {
      pkg.root.panel.northFixed()
      this.view.unmount()
      this.comp.destroy()
    })
  }
}
