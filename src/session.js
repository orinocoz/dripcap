import 'dripper/type'
import { EventEmitter } from 'events'
import Packet from 'dripper/packet'
import net from 'net'
import tmp from 'temporary'
import msgpack from 'msgcap'
import remote from 'remote'
const BrowserWindow = remote.require('browser-window')

export default class Session extends EventEmitter {
  constructor(_filterPath) {
    super()
    this._filterPath = _filterPath
    let file = new tmp.File()
    let sock = file.path
    file.unlink()

    this._server = net.createServer((c) => {
      this._msgdec = new msgpack.Decoder(c)
      this._msgdec.on('data', (packet) => {
        this.emit('packet', new Packet(packet))
      })
    })

    this._server.listen(sock)

    this._window = new BrowserWindow({show: false})
    this._window.loadURL('file://' + __dirname + '/../session.html')

    let arg = JSON.stringify(this._filterPath)
    this._window.webContents.executeJavaScript(`session.filterPath = ${arg}`)
    arg = JSON.stringify(sock)
    this._window.webContents.executeJavaScript(`session.connect(${arg})`)

    this._loaded = new Promise((res) => {
      this._window.webContents.once('did-finish-load', () => res())
    })
  }

  addCapture(iface, options = {}) {
    this._loaded.then(() => {
      let settings = {iface: iface, options: options}
      let arg = JSON.stringify(settings)
      this._window.webContents.executeJavaScript(`session.capture(${arg})`)
      dripcap.pubsub.pub('Core: Capturing Settings', settings)
    })
  }

  addDecoder(decoder) {
    this._loaded.then(() => {
      let arg = JSON.stringify(decoder)
      this._window.webContents.executeJavaScript(`session.load(${arg})`)
    })
  }


  start() {
    this._loaded.then(() => {
      this._window.webContents.executeJavaScript('session.stop()')
      this._window.webContents.executeJavaScript('session.start()')
      dripcap.pubsub.pub('Core: Capturing Status', true)
    })
  }

  stop() {
    this._loaded.then(() => {
      this._window.webContents.executeJavaScript('session.stop()')
      dripcap.pubsub.pub('Core: Capturing Status', false)
    })
  }

  close() {
    this._loaded.then(() => this._window.close())
  }
}
