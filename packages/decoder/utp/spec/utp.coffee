fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
IPv4Decoder = require('../../ipv4/lib/ipv4')
UDPDecoder = require('../../udp/lib/udp')
UTPDecoder = require('../lib/utp')
{PayloadSlice} = require('dripcap/type')

describe "uTP", ->
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
        (new UDPDecoder()).analyze(packet, layer.layers['::Ethernet::IPv4::<UDP>']).then (layer) ->
          (new UTPDecoder()).analyze(packet, layer.layers['::Ethernet::IPv4::UDP']).then ->
          done()

  it "decodes a uTP frame from an UDP frame", ->
    layer = packet
      .layers['::<Ethernet>']
      .layers['::Ethernet::<IPv4>']
      .layers['::Ethernet::IPv4::<UDP>']
      .layers['::Ethernet::IPv4::UDP']
      .layers['::Ethernet::IPv4::UDP::uTP']

    expect(layer.namespace).toEqual '::Ethernet::IPv4::UDP::uTP'
    expect(layer.name).toEqual 'μTP'
    expect(layer.summary).toEqual '[ST_STATE] seq:34897 ack:47930'
