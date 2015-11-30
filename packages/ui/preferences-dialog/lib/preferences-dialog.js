import $ from 'jquery'
import riot from 'riot'
import { Component, Panel } from 'dripper/component'

export default class PreferencesDialog {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
    dripcap.package.load('main-view').then((pkg) => {
      dripcap.package.load('modal-dialog').then((pkg) => {
        $(() => {
          this.panel = new Panel
          let n = $('<div>').appendTo($('body'))
          this._view = riot.mount(n[0], 'preferences-dialog')[0]
          $(this._view.root).find('.content').append($('<div class="root-container" />').append(this.panel.root))

          dripcap.action.on('Core: Preferences', () => {
            this._view.show()
            this._view.update()
          })
        })
      })
    })
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.keybind.unbind('enter', '[riot-tag=preferences-dialog] .content')
    this._view.unmount()
    this.comp.destroy()
  }
}
