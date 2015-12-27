fs = require('fs')
zlib = require('zlib')
os = require('os')
crypto = require('crypto')
childProcess = require('child_process')
msgpack = require('msgpack-lite')
Layer = require('dripcap/layer')
{PayloadSlice} = require('dripcap/type')
{EventEmitter} = require('events')

testdata = process.env['PAPERFILTER_TESTDATA']

class PaperFilter extends EventEmitter
  constructor: ->
    @exec = __dirname + '/bin/paperfilter'
    @path =
      if testdata?
        @exec
      else if process.platform == 'darwin'
        '/usr/local/lib/paperfilter'
      else
        '/usr/bin/paperfilter'

  setup: ->
    unless @test()
      @setcap()

  test: ->
    return true if testdata?
    digest = crypto.createHash('sha1').update(fs.readFileSync(@exec)).digest('hex')
    try
      if crypto.createHash('sha1').update(fs.readFileSync(@path)).digest('hex') != digest
        return false
      childProcess.execFileSync @path, ['testcap']
    catch err
      if err?
        if err.code == 'ENOENT' || err.status == 1
          return false
        else
          throw err
    true

  setcap: ->
    return if testdata?
    switch process.platform
      when 'linux'
        try
          script = "cp #{@exec} #{@path} && #{@path} setcap"
          if process.env['XDG_CURRENT_DESKTOP'] == 'KDE'
            childProcess.execFileSync 'kdesudo', ['--', 'sh', '-c', script]
          else
            childProcess.execFileSync 'gksu', ['--user', 'root', '--', 'sh', '-c', script]
        catch err
          if err?
            if err.status == 126
              return false
            else
              throw err
      when 'darwin'
        try
          script = "mkdir /usr/local/lib ; cp #{@exec} #{@path} && #{@path} setcap"
          childProcess.execFileSync 'osascript', ['-e', "do shell script \"#{script}\" with administrator privileges"]
        catch err
          if err?
            if err.status == -1
              return false
            else
              throw err

  list: ->
    new Promise (res, rej) =>
      args = []
      if testdata?
        args.push '-s'
        args.push testdata
      args.push 'list'
      childProcess.execFile @path, args, encoding: 'buffer', (err, stdout) ->
        if err?
          rej(err)
        else
          res(msgpack.decode(stdout))

  getInterface: (name) ->
    @list().then (list) ->
      for i in list
        return Promise.resolve(i) if i.name == name
      Promise.reject()

  start: (iface, options = {}) ->
    @stop()
    @getInterface(iface).then (ifs) =>
      options.filter = '' unless typeof options.filter == 'string'
      options.promisc ?= false
      options.snaplen ?= 1600
      args = []
      if testdata?
        args.push '-s'
        args.push testdata
      if Number.isInteger(options.snaplen) && options.snaplen > 0
        args.push '-l'
        args.push options.snaplen.toString()
      args.push '-p' if options.promisc
      args.push 'capture'
      args.push(iface)
      args.push(options.filter) if options.filter.length > 0
      @process = childProcess.spawn(@path, args)
      @decoder = msgpack.createDecodeStream()
      @process.stdout.pipe(@decoder).on 'data', (data) =>
        date = new Date()
        date.setTime(data.timestamp[0] * 1000 + data.timestamp[1] / 1000000)
        linkName = linkid2name(ifs.link)
        namespace = '::<' + linkName + '>'
        summary = "[#{linkName}]"
        layer = new Layer(namespace, name: 'Raw Frame', payload: data.payload, summary: summary)
        packet =
          timestamp: date
          interface: iface
          options: options
          payload: data.payload
          caplen: data.capture_length
          length: data.length
          truncated: data.truncated
          layers: [
            namespace: namespace
            name: 'Raw Frame'
            payload: new PayloadSlice(0, data.payload.length)
            summary: summary
          ]
        @emit('packet', packet)
    .catch ->
      throw new Error 'interface not found'

  stop: ->
    if @process
      @process.kill()
      @process = null
    if @decoder
      @decoder.removeAllListeners()
      @decoder = null

module.exports = PaperFilter

linkid2name = (id) ->
  name = idmap[id]
  name ?= id.toString()
  name

idmap = # http://www.tcpdump.org/linktypes.html
  0: 'Null'
  1: 'Ethernet'
  3: 'AX.25'
  6: 'TokenRing'
  7: 'ARCNET'
  8: 'SLIP'
  9: 'PPP'
  10: 'FDDI'
  50: 'PPP-HDLC'
  51: 'PPPoE'
  100: 'ATM-RFC1483'
  101: 'RAW'
  104: 'CiscoHDLC'
  105: 'IEEE802.11'
  107: 'FrameRelay'
  108: 'Loop'
  113: 'LinuxSLL'
  114: 'LocalTalk'
  117: 'pflog'
  119: 'PrismHeader'
  122: 'IP-over-FibreChannel'
  123: 'SunATM'
  127: 'IEEE802.11-Radiotap'
  129: 'ARCNET-Linux'
  138: 'Apple-IP-over-IEEE1394'
  139: 'MTP2-with-PHDR'
  140: 'MTP2'
  141: 'MTP3'
  142: 'SCCP'
  143: 'DOCSIS'
  144: 'LinuxIRDA'
  147: 'USER0'
  148: 'USER1'
  149: 'USER2'
  150: 'USER3'
  151: 'USER4'
  152: 'USER5'
  153: 'USER6'
  154: 'USER7'
  155: 'USER8'
  156: 'USER9'
  157: 'USER10'
  158: 'USER11'
  159: 'USER12'
  160: 'USER13'
  161: 'USER14'
  162: 'USER15'
  163: 'IEEE802.11-AVS'
  165: 'BACnetMS/TP'
  166: 'PPP-PPPD'
  169: 'GPRS-LLC'
  177: 'LinuxLAPD'
  187: 'Bluetooth-HCI-UART'
  189: 'USB-Linux'
  192: 'PPI'
  195: 'IEEE802.15.4'
  196: 'SITA'
  197: 'ERF'
  201: 'Bluetooth-HCI-UART-with-PHDR'
  202: 'AX.25-KISS'
  203: 'LAPD'
  204: 'PPP-with-DIR'
  205: 'CiscoHDLC-with-DIR'
  206: 'FrameRelay-with-DIR'
  209: 'IPMB-Linux'
  215: 'IEEE802.15.4-non-ASK-PHY'
  220: 'USB-Linux-Mapped'
  224: 'FC-2'
  225: 'FC-2-with-FrameDelims'
  226: 'IPNET'
  227: 'CAN-SocketCAN'
  228: 'IPv4'
  229: 'IPv6'
  230: 'IEEE802.15.4-no-FCS'
  231: 'D-Bus'
  235: 'DVB-CI'
  236: 'MUX27010'
  237: 'STANAG5066'
  239: 'NFLOG'
  240: 'netANALYZER'
  241: 'netANALYZER-transparent'
  242: 'IPOIB'
  243: 'MPEG-2-TS'
  244: 'NG40'
  245: 'NFC-LLCP'
  247: 'InfiniBand'
  248: 'SCTP'
  249: 'USBPcap'
  250: 'RTAC-Serial'
  251: 'BluetoothLE'
  253: 'Netlink'
  254: 'Bluetooth-Linux-Monitor'
  255: 'Bluetooth-BREDR'
  256: 'BluetoothLE-with-PHDR'
  257: 'PROFIBUS'
  258: 'PKTAP'
  259: 'EPON'
  260: 'IPMI'
  261: 'Z-WAVE-R1-R2'
  262: 'Z-WAVE-R3'
  263: 'WattStopper-DLM'
