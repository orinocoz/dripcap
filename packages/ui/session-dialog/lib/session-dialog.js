import $ from 'jquery'
import riot from 'riot'
import { Component } from 'dripper/component'

export default class SessionDialog {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)
    dripcap.package.load('main-view').then((pkg) => {
      dripcap.package.load('modal-dialog').then((pkg) => {
        $(() => {
          let n = $('<div>').addClass('container').appendTo($('body'))
          this.view = riot.mount(n[0], 'session-dialog')[0]

          dripcap.keybind.bind('enter', '[riot-tag=session-dialog] .content', () => {
            $(this.view.tags['modal-dialog'].start).click()
          })

          dripcap.getInterfaceList().then((list) => {
            this.view.setInterfaceList(list)
            this.view.update()
          })

          dripcap.action.on('Core: New Session', () => {
            dripcap.getInterfaceList().then((list) => {
              this.view.setInterfaceList(list)
              this.view.show()
              this.view.update()
            })
          })
        })
      })
    })
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.keybind.unbind('enter', '[riot-tag=session-dialog] .content')
    this.view.unmount()
    this.comp.destroy()
  }
}
