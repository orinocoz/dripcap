fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
IPv4Decoder = require('../lib/ipv4')
{PayloadSlice} = require('dripcap/type')

describe "IPv4", ->
  payload = fs.readFileSync(__dirname + '/data.bin')

  packet =
    timestamp: new Date()
    interface: 'eth0'
    options: {}
    payload: payload
    layers:
      '::<Ethernet>':
        namespace: '::<Ethernet>'
        name: 'Raw Frame'
        payload: new PayloadSlice(0, payload.length)
        summary: ''

  beforeEach (done) ->
    (new EthernetDecoder()).analyze(packet, packet.layers['::<Ethernet>']).then (layer) ->
      (new IPv4Decoder()).analyze(packet, layer.layers['::Ethernet::<IPv4>']).then (layer) ->
        done()

  it "decodes an ipv4 frame from an ethernet frame", ->
    layer = packet
      .layers['::<Ethernet>']
      .layers['::Ethernet::<IPv4>']
      .layers['::Ethernet::IPv4::<TCP>']
    expect(layer.namespace).toEqual '::Ethernet::IPv4::<TCP>'
    expect(layer.name).toEqual 'IPv4'
    expect(layer.summary).toEqual '[TCP] 192.168.150.35 -> 52.21.92.31'
    expect(layer.attrs.version).toEqual 4
    expect(layer.attrs.headerLength).toEqual 5
    expect(layer.attrs.type).toEqual 0
    expect(layer.attrs.totalLength).toEqual 52
    expect(layer.attrs.id).toEqual 34071
    expect(layer.attrs.flags.toString()).toEqual "Don't Fragment (2)"
    expect(layer.attrs.fragmentOffset).toEqual 64
    expect(layer.attrs.ttl).toEqual 64
    expect(layer.attrs.protocol.toString()).toEqual 'TCP (6)'
    expect(layer.attrs.checksum).toEqual 52908
    expect(layer.attrs.dst.toString()).toEqual '52.21.92.31'
    expect(layer.attrs.src.toString()).toEqual '192.168.150.35'
