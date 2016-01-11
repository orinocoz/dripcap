fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
IPv4Decoder = require('../../ipv4/lib/ipv4')
UDPDecoder = require('../../udp/lib/udp')
DNSDecoder = require('../lib/dns')
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
          (new DNSDecoder()).analyze(packet, layer.layers['::Ethernet::IPv4::UDP']).then ->
          done()

  it "decodes a uTP frame from an UDP frame", ->
    layer = packet
      .layers['::<Ethernet>']
      .layers['::Ethernet::<IPv4>']
      .layers['::Ethernet::IPv4::<UDP>']
      .layers['::Ethernet::IPv4::UDP']
      .layers['::Ethernet::IPv4::UDP::DNS']

    expect(layer.namespace).toEqual '::Ethernet::IPv4::UDP::DNS'
    expect(layer.name).toEqual 'DNS'
    expect(layer.summary).toEqual '[QUERY] [No Error] qd:1 an:0 ns:0 ar:0'
    expect(layer.attrs.id).toEqual 35116
    expect(layer.attrs.qr).toEqual false
    expect(layer.attrs.opcode.name).toEqual 'QUERY'
    expect(layer.attrs.aa).toEqual false
    expect(layer.attrs.tc).toEqual false
    expect(layer.attrs.rd).toEqual true
    expect(layer.attrs.ra).toEqual false
    expect(layer.attrs.rcode.name).toEqual 'No Error'
    expect(layer.attrs.qdCount).toEqual 1
    expect(layer.attrs.anCount).toEqual 0
    expect(layer.attrs.nsCount).toEqual 0
    expect(layer.attrs.arCount).toEqual 0
