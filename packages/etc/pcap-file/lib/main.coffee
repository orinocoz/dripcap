$ = require('jquery')
fs = require('fs')
remote = require('remote')
MenuItem = remote.require('menu-item')
dialog = remote.require('dialog')
config = require('dripcap/config')
Layer = require('dripcap/layer')
Session = require('dripcap/session')
{linkid2name} = require('dripcap/enum')
{PayloadSlice} = require('dripcap/type')

class Pcap
  constructor: (path) ->
    data = fs.readFileSync path
    throw new Error 'too short global header' if data.length < 24

    magicNumber = data.readUInt32BE 0, true
    switch magicNumber
      when 0xd4c3b2a1
        littleEndian = true
        nanosec = false
      when 0xa1b2c3d4
        littleEndian = false
        nanosec = false
      when 0x4d3cb2a1
        littleEndian = true
        nanosec = true
      when 0xa1b23c4d
        littleEndian = false
        nanosec = true
      else
        throw new Error 'wrong magic_number'

    if littleEndian
      @versionMajor = data.readUInt16LE 4, true
      @versionMinor = data.readUInt16LE 6, true
      @thiszone = data.readInt16LE 8, true
      @sigfigs = data.readUInt32LE 12, true
      @snaplen = data.readUInt32LE 16, true
      @network = data.readUInt32LE 20, true
    else
      @versionMajor = data.readUInt16BE 4, true
      @versionMinor = data.readUInt16BE 6, true
      @thiszone = data.readInt16BE 8, true
      @sigfigs = data.readUInt32BE 12, true
      @snaplen = data.readUInt32BE 16, true
      @network = data.readUInt32BE 20, true

    @packets = []

    offset = 24
    while offset < data.length
      throw new Error 'too short packet header' if data.length - offset < 16
      if littleEndian
        tsSec = data.readUInt32LE offset, true
        tsUsec = data.readUInt32LE offset + 4, true
        inclLen = data.readUInt32LE offset + 8, true
        origLen = data.readUInt32LE offset + 12, true
      else
        tsSec = data.readUInt32BE offset, true
        tsUsec = data.readUInt32BE offset + 4, true
        inclLen = data.readUInt32BE offset + 8, true
        origLen = data.readUInt32BE offset + 12, true

      offset += 16
      throw new Error 'too short packet body' if data.length - offset < inclLen

      timestamp =
        if nanosec
          new Date(tsSec * 1000 + tsUsec / 1000000)
        else
          new Date(tsSec * 1000 + tsUsec / 1000)

      payload = data.slice offset, offset + inclLen
      linkName = linkid2name @network
      namespace = '::<' + linkName + '>'
      summary = "[#{linkName}]"
      layer = new Layer(namespace, name: 'Raw Frame', payload: payload, summary: summary)

      packet =
        timestamp: timestamp
        interface: ''
        options: {}
        payload: payload
        caplen: inclLen
        length: origLen
        truncated: inclLen < origLen
        layers:
          "#{namespace}":
            namespace: namespace
            name: 'Raw Frame'
            payload: new PayloadSlice(0, payload.length)
            summary: summary
            namespace: namespace

      @packets.push packet
      offset += inclLen

class PcapFile
  activate: ->
    dripcap.keybind.bind 'command+o', '!menu', 'pcap-file:open'

    @fileMenu = (menu, e) ->
      menu.append new MenuItem
        label: 'Import Pcap File...'
        accelerator: dripcap.keybind.get('!menu', 'pcap-file:open')
        click: -> dripcap.action.emit 'pcap-file:open'

      menu.append new MenuItem type: 'separator'
      menu

    dripcap.menu.registerMain 'File', @fileMenu, 5

    dripcap.action.on 'pcap-file:open', ->
      path = dialog.showOpenDialog remote.getCurrentWindow(),
      filters: [
        name: 'PCAP File'
        extensions: ['pcap']
      ]

      @_open(path[0]) if path?

    @_drop = (e) =>
      e.preventDefault()
      files = e.originalEvent.dataTransfer.files
      if files.length > 0 && files[0].path.endsWith '.pcap'
        @_open(files[0].path)

    new Promise (res) =>
      dripcap.package.load('main-view').then (pkg) =>
        $ =>
          $('body').on 'drop', @_drop
          res()

  _open: (path) ->
    pcap = new Pcap path
    sess = new Session(config.filterPath)
    dripcap.session.emit('created', sess)

    count = 0

    do (sess=sess, len=pcap.packets.length) ->
      sess.on 'packet', ->
        count++
        sess.close() if count >= len

    for pkt in pcap.packets
      sess.decode pkt

  deactivate: ->
    $('body').off 'drop', @_drop
    dripcap.action.removeAllListeners 'pcap-file:open'
    dripcap.keybind.unbind 'command+o', '!menu', 'pcap-file:open'
    dripcap.menu.unregisterMain 'File', @fileMenu

module.exports = PcapFile
