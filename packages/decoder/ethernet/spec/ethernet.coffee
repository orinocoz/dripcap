fs = require('fs')
EthernetDecoder = require('../lib/ethernet')
{PayloadSlice} = require('dripper/type')

describe "Ethernet", ->
  payload = fs.readFileSync(__dirname + '/data.bin')

  packet =
    timestamp: new Date()
    interface: 'eth0'
    options: {}
    payload: payload
    layers: [
      namespace: '::<Ethernet>'
      name: 'Raw Frame'
      payload: new PayloadSlice(0, payload.length)
      summary: ''
    ]

  beforeEach (done) ->
    decoder = new EthernetDecoder()
    decoder.analyze(packet).then -> done()

  it "decodes an ethernet frame from a raw frame", ->
    layer = packet.layers[1]
    expect(layer.namespace).toEqual '::Ethernet::<ARP>'
    expect(layer.name).toEqual 'Ethernet'
    expect(layer.summary).toEqual '[ARP] 00:10:38:23:14:b0 -> 74:27:ea:0f:18:95'
    expect(layer.attrs.dst.toString()).toEqual '74:27:ea:0f:18:95'
    expect(layer.attrs.src.toString()).toEqual '00:10:38:23:14:b0'
    expect(layer.attrs.etherType.toString()).toEqual 'ARP (2054)'

describe "Ethernet", ->
  payload = fs.readFileSync(__dirname + '/data2.bin')

  packet =
    timestamp: new Date()
    interface: 'eth0'
    options: {}
    payload: payload
    layers: [
      namespace: '::<Ethernet>'
      name: 'Raw Frame'
      payload: new PayloadSlice(0, payload.length)
      summary: ''
    ]

  beforeEach (done) ->
    decoder = new EthernetDecoder()
    decoder.analyze(packet).then -> done()

  it "decodes an ethernet frame from a raw frame", ->
    layer = packet.layers[1]
    expect(layer.namespace).toEqual '::Ethernet'
    expect(layer.name).toEqual 'Ethernet'
    expect(layer.summary).toEqual '00:1a:eb:33:bd:b2 -> 01:80:c2:00:00:00'
    expect(layer.attrs.dst.toString()).toEqual '01:80:c2:00:00:00'
    expect(layer.attrs.src.toString()).toEqual '00:1a:eb:33:bd:b2'
