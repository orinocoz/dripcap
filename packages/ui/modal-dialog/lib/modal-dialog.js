import $ from 'jquery'
import riot from 'riot'
import { Component, Panel } from 'dripper/component'

export default class ModalDialog {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    this.comp.destroy()
  }
}
