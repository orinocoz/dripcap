fs = require('fs')
zlib = require('zlib')
os = require('os')
path = require('path')
crypto = require('crypto')
childProcess = require('child_process')
msgpack = require('msgpack-lite')
Layer = require('dripcap/layer')
{linkid2name} = require('dripcap/enum')
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
        helperPath = path.join __dirname, "../../../../Frameworks/Dripcap Helper Installer.app/Contents/MacOS/Dripcap Helper Installer"

        try
          childProcess.execFileSync helperPath
        catch err
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
          layers:
            "#{namespace}":
              name: 'Raw Frame'
              payload: new PayloadSlice(0, data.payload.length)
              summary: summary
              namespace: namespace
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
