require('dripper/type')
{EventEmitter} = require('events')
Packet = require('dripper/packet')
net = require('net')
tmp = require('temporary')
msgpack = require('msgcap')
remote = require('remote')
BrowserWindow = remote.require('browser-window')

class Session extends EventEmitter
  constructor: (@filterPath) ->
    file = new tmp.File()
    sock = file.path
    file.unlink()

    @server = net.createServer (c) =>
      @msgdec = new msgpack.Decoder(c)
      @msgdec.on 'data', (packet) =>
        @emit 'packet', new Packet packet

    @server.listen sock

    @window = new BrowserWindow(show: false)
    @window.loadUrl 'file://' + __dirname + '/../session.html'

    arg = JSON.stringify @filterPath
    @window.webContents.executeJavaScript("session.filterPath = #{arg}")
    arg = JSON.stringify sock
    @window.webContents.executeJavaScript("session.connect(#{arg})")

    @loaded = new Promise (res) =>
      @window.webContents.once 'did-finish-load', -> res()

  addCapture: (iface, options = {}) ->
    @loaded.then =>
      settings = {iface: iface, options: options}
      arg = JSON.stringify settings
      @window.webContents.executeJavaScript("session.capture(#{arg})")
      dripcap.pubsub.pub 'Core:updateCapturingSettings', settings, 1

  addDecoder: (decoder) ->
    @loaded.then =>
      arg = JSON.stringify decoder
      @window.webContents.executeJavaScript("session.load(#{arg})")

  start: ->
    @loaded.then =>
      @window.webContents.executeJavaScript('session.stop()')
      @window.webContents.executeJavaScript('session.start()')
      dripcap.pubsub.pub 'Core: Capturing Status Updated', true, 1

  stop: ->
    @loaded.then =>
      @window.webContents.executeJavaScript('session.stop()')
      dripcap.pubsub.pub 'Core: Capturing Status Updated', false, 1

  close: ->
    @loaded.then =>
      @window.close()

module.exports = Session
