import $ from 'jquery'
import _ from 'underscore'
import riot from 'riot'
import fs from 'fs'
import { Component } from 'dripper/component'
import Filter from 'dripper/filter'
import remote from 'remote'
import {clipboard} from 'electron'
const Menu = remote.require('menu')
const MenuItem = remote.require('menu-item')
const dialog = remote.require('dialog')

class PacketTable {
  constructor(container, table) {
    this.container = container
    this.table = table
    this.sectionSize = 1000
    this.sections = []
    this.currentSection = null
    this.updateSection = _.debounce(() => this.update, 100)
    this.container.scroll(() => this.updateSection())
  }

  clear() {
    this.sections = []
    this.currentSection = null
    this.table.find('tr:has(td)').remove()
  }

  autoScroll() {
    let scroll = this.container.scrollTop() + this.container.height()
    let height = this.container[0].scrollHeight
    if (height - scroll < 64) {
      this.container.scrollTop(height)
    }
  }

  update() {
    let top = this.container.scrollTop()
    let bottom = this.container.height() + top
    let begin = Math.floor(top / (16 * this.sectionSize))
    let end = Math.ceil(bottom / (16 * this.sectionSize))

    let topPad = 0
    let bottomPad = 0

    this.sections.forEach((s, i) => {
      if (i < begin) {
        topPad += 16 * s.children().length
        topPad += 16 * s.data('tr').length
        s.hide()
      } else if (i > end) {
        bottomPad += 16 * s.children().length
        bottomPad += 16 * s.data('tr').length
        s.hide()
      } else {
        let tr = s.data('tr')
        if (tr.length > 0) {
          for (t of tr) {
            s.append(t)
          }
          s.data('tr', [])
        }
        s.show()
      }
    })

    topPad = Math.max(10, topPad)
    bottomPad = Math.max(10, bottomPad)
    this.table.css('padding-top', `${topPad}px`)
    this.table.css('padding-bottom', `${bottomPad}px`)
  }

  append(pkt) {
    let self = this
    let tr = $('<tr>')
      .append(`<td>${ pkt.name }</td>`)
      .append(`<td>${ pkt.attrs.src }</td>`)
      .append(`<td>${ pkt.attrs.dst }</td>`)
      .append(`<td>${ pkt.length }</td>`)
      .attr('data-filter-rev', '0')
      .data('packet', pkt)
      .on('click', function() {
        if (self.selectedLine != null) {
          self.selectedLine.removeClass('selected')
        }
        self.selectedLine = $(this)
        self.selectedLine.addClass('selected')
      }).on('click', function() {
        dripcap.pubsub.pub('PacketListView:select', $(this).data('packet'))
      }).on('contextmenu', (e) => {
        e.preventDefault()
        this.selctedPacket = $(e.currentTarget).data('packet')
        dripcap.menu.popup('PacketListView: PacketMenu', this, remote.getCurrentWindow())
      })

    process.nextTick(() => {
      if (this.currentSection == null || this.currentSection.children().length + this.currentSection.data('tr').length >= this.sectionSize) {
        this.currentSection = $('<tbody>').hide()
        this.currentSection.data('tr', [])
        this.sections.push(this.currentSection)
        this.table.append(this.currentSection)
        this.update()
      }

      this.updateSection()

      if (this.currentSection.is(':visible'))
        this.currentSection.append(tr)
      else
        this.currentSection.data('tr').push(tr)
    })
  }
}

export default class PacketListView {
  activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`)

    dripcap.package.load('main-view').then((pkg) => {
      $(() => {
        let m = $('<div class="wrapper noscroll" />')
        pkg.root.panel.left('packet-list-view', m)

        let n = $('<div class="wrapper" />').attr('tabIndex', '0').appendTo(m)
        this.list = riot.mount(n[0], 'packet-list-view', {items: []})

        let h = $('<div class="wrapper noscroll" />').css('bottom', 'auto').appendTo(m)
        riot.mount(h[0], 'packet-list-view-header')

        dripcap.session.on('created', (session) => {
          let container = n
          let packets = []

          let main = $('[riot-tag=packet-list-view] table.main')
          let sub = $('[riot-tag=packet-list-view] table.sub').hide()

          let mhead = main.find('tr.head').detach()
          let shead = sub.find('tr.head').detach()
          main.empty().append(mhead)
          sub.empty().append(shead)
          let mainTable = new PacketTable(container, main)
          let subTable = new PacketTable(container, sub)

          dripcap.pubsub.sub('PacketFilterView:filter', _.debounce((f) => {
            if (this._filterInterval != null) {
              clearInterval(this._filterInterval)
              this._filterInterval = null
            }

            if (this._filter != null) {
              this._filter.terminate()
              this._filter = null
            }

            if (f.length > 0) {
              this._filter = new Filter(f)
              this._filter.on('filtered', (pkt) => {
                subTable.append(pkt)
              })

              subTable.clear()
              for (pkt of packets) {
                this._filter.process(pkt)
              }

              sub.show()
              main.hide()
            } else {
              sub.hide()
              main.show()
            }
          }, 400))

          session.on('packet', (pkt) => {
            packets.push(pkt)
            mainTable.append(pkt)
            if (this._filter != null) {
              this._filter.process(pkt)
            }
            mainTable.autoScroll()
            subTable.autoScroll()
          })
        })
      })
    })

    this.packetMenu = function(menu, e) {
      let exportRawData = () => {
        let filename = `${this.selctedPacket.interface}-${this.selctedPacket.timestamp.toISOString()}.bin`
        let path = dialog.showSaveDialog(remote.getCurrentWindow(), {defaultPath: filename})
        if (path != null) {
          fs.writeFileSync(path, this.selctedPacket.payload)
        }
      }

      let copyAsJSON = () => {
        clipboard.writeText(JSON.stringify(this.selctedPacket, null, ' '))
      }

      menu.append(new MenuItem({label: 'Export raw data', click: exportRawData}))
      menu.append(new MenuItem({label: 'Copy Packet as JSON', click: copyAsJSON}))
      return menu
    }

    dripcap.menu.register('PacketListView: PacketMenu', this.packetMenu)
  }

  updateTheme(theme) {
    this.comp.updateTheme(theme)
  }

  deactivate() {
    dripcap.menu.unregister('PacketListView: PacketMenu', this.packetMenu)
    dripcap.package.load('main-view').then((pkg) => {
      pkg.root.panel.left('packet-list-view')
      this.list[0].unmount()
      this.comp.destroy()
    })
  }
}
