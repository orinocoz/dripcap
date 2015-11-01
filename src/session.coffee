require('dripper/type')
{EventEmitter} = require('events')
Packet = require('dripper/packet')
net = require('net')
tmp = require('temporary')
msgpack = require('msgcap')
remote = require('remote')
BrowserWindow = remote.require('browser-window')

class Session extends EventEmitter
  constructor: (@_filterPath) ->
    file = new tmp.File()
    sock = file.path
    file.unlink()

    @_server = net.createServer (c) =>
      @_msgdec = new msgpack.Decoder(c)
      @_msgdec.on 'data', (packet) =>
        @emit 'packet', new Packet packet

    @_server.listen sock

    @_window = new BrowserWindow(show: false)
    @_window.loadUrl 'file://' + __dirname + '/../session.html'

    arg = JSON.stringify @_filterPath
    @_window.webContents.executeJavaScript("session.filterPath = #{arg}")
    arg = JSON.stringify sock
    @_window.webContents.executeJavaScript("session.connect(#{arg})")

    @_loaded = new Promise (res) =>
      @_window.webContents.once 'did-finish-load', -> res()

  addCapture: (iface, options = {}) ->
    @_loaded.then =>
      settings = {iface: iface, options: options}
      arg = JSON.stringify settings
      @_window.webContents.executeJavaScript("session.capture(#{arg})")
      dripcap.pubsub.pub 'Core:updateCapturingSettings', settings, 1

  addDecoder: (decoder) ->
    @_loaded.then =>
      arg = JSON.stringify decoder
      @_window.webContents.executeJavaScript("session.load(#{arg})")

  start: ->
    @_loaded.then =>
      @_window.webContents.executeJavaScript('session.stop()')
      @_window.webContents.executeJavaScript('session.start()')
      dripcap.pubsub.pub 'Core: Capturing Status Updated', true, 1

  stop: ->
    @_loaded.then =>
      @_window.webContents.executeJavaScript('session.stop()')
      dripcap.pubsub.pub 'Core: Capturing Status Updated', false, 1

  close: ->
    @_loaded.then =>
      @_window.close()

module.exports = Session
