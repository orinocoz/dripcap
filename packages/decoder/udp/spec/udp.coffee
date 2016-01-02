fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
IPv4Decoder = require('../../ipv4/lib/ipv4')
UDPDecoder = require('../lib/udp')
{PayloadSlice} = require('dripcap/type')

describe "UDP", ->
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
        (new UDPDecoder()).analyze(packet, layer.layers['::Ethernet::IPv4::<UDP>']).then ->
          done()

  it "decodes a udp frame from an ipv4 frame", ->
    layer = packet
      .layers['::<Ethernet>']
      .layers['::Ethernet::<IPv4>']
      .layers['::Ethernet::IPv4::<UDP>']
      .layers['::Ethernet::IPv4::UDP']
    expect(layer.namespace).toEqual '::Ethernet::IPv4::UDP'
    expect(layer.name).toEqual 'UDP'
    expect(layer.summary).toEqual '192.168.150.35:9466 -> 8.8.8.8:53'
    expect(layer.attrs.src.toString()).toEqual '192.168.150.35:9466'
    expect(layer.attrs.dst.toString()).toEqual '8.8.8.8:53'
    expect(layer.attrs.length).toEqual 56
    expect(layer.attrs.checksum).toEqual 19264
