require('dripcap/type')
{EventEmitter} = require('events')
Packet = require('dripcap/packet')
net = require('net')
temp = require('temp')
msgpack = require('msgcap')
remote = require('remote')
BrowserWindow = remote.require('browser-window')

class Session extends EventEmitter
  constructor: (@_filterPath) ->
    sock = temp.path(suffix: '.sock')

    @_window = new BrowserWindow(show: false)
    @_window.loadURL 'file://' + __dirname + '/session.html'

    @_loaded = new Promise (res) =>
      @_window.webContents.once 'did-finish-load', -> res()
    .then =>
      new Promise (res) =>
        @_server = net.createServer (c) =>
          @_msgenc = new msgpack.Encoder(c)
          @_msgdec = new msgpack.Decoder(c)
          @_msgdec.on 'data', (packet) =>
            @emit 'packet', new Packet packet
          res()
        @_server.listen sock
        arg = JSON.stringify @_filterPath
        @_window.webContents.executeJavaScript("session.filterPath = #{arg}")
        arg = JSON.stringify sock
        @_window.webContents.executeJavaScript("session.connect(#{arg})")

    @_exec = @_loaded

  addCapture: (iface, options = {}) ->
    settings = {iface: iface, options: options}
    arg = JSON.stringify settings
    @_execute("session.capture(#{arg})").then ->
      dripcap.pubsub.pub 'core:capturing-settings', settings

  addDecoder: (decoder) ->
    arg = JSON.stringify decoder
    @_execute("session.load(#{arg})")

  decode: (packet) ->
    @_execute('').then =>
      @_msgenc.encode type: 'packet', body: packet

  start: ->
    @_execute('session.stop()').then =>
      @_execute('session.start()')
    .then =>
      dripcap.pubsub.pub 'core:capturing-status', true

  stop: ->
    @_execute('session.stop()').then ->
      dripcap.pubsub.pub 'core:capturing-status', false

  _execute: (js) ->
    @_exec = @_exec.then =>
      @_msgenc.encode type: 'script', body: js

  close: ->
    @_loaded.then =>
      @_server.close()
      @_window.close()

module.exports = Session
