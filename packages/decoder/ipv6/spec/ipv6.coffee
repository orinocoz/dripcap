fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
IPv6Decoder = require('../lib/ipv6')
{PayloadSlice} = require('dripcap/type')

describe "IPv6", ->
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
      (new IPv6Decoder()).analyze(packet, layer.layers['::Ethernet::<IPv6>']).then (layer) ->
        done()

  it "decodes an IPv6 frame from an ethernet frame", ->
    layer = packet
      .layers['::<Ethernet>']
      .layers['::Ethernet::<IPv6>']
      .layers['::Ethernet::IPv6::<ICMP>']
    expect(layer.namespace).toEqual '::Ethernet::IPv6::<ICMP>'
    expect(layer.name).toEqual 'IPv6'
    expect(layer.summary).toEqual '[ICMP] fe80::7627:eaff:fe0f:1895 -> ff02::1:ff0f:1895'
    expect(layer.attrs.version).toEqual 6
    expect(layer.attrs.trafficClass).toEqual 0
    expect(layer.attrs.flowLevel).toEqual 0
    expect(layer.attrs.payloadLength).toEqual 32
    expect(layer.attrs.protocol.toString()).toEqual 'ICMP (58)'
    expect(layer.attrs.hopLimit).toEqual 1
    expect(layer.attrs.dst.toString()).toEqual 'ff02::1:ff0f:1895'
    expect(layer.attrs.src.toString()).toEqual 'fe80::7627:eaff:fe0f:1895'
