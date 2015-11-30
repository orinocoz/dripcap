import $ from 'jquery'
import { Component, Panel } from 'dripper/component'

export default class MainView {
  activate() {
    this._comp = new Component(`${__dirname}/../less/*.less`)
    $(() => {
      this.panel = new Panel
      this._elem = $('<div id="main-view">').append(this.panel.root)
      this._elem.appendTo($('body'))
    })
  }

  updateTheme(theme) {
    this._comp.updateTheme(theme)
  }

  deactivate() {
    this._elem.remove()
    this._comp.destroy()
  }
}
