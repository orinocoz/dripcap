fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
ARPDecoder = require('../lib/arp')
{PayloadSlice} = require('dripcap/type')

describe "ARP", ->
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
      (new ARPDecoder()).analyze(packet, layer.layers['::Ethernet::<ARP>']).then (layer) ->
        done()

  it "decodes an arp frame from an ethernet frame", ->
    layer = packet
      .layers['::<Ethernet>']
      .layers['::Ethernet::<ARP>']
      .layers['::Ethernet::ARP']
    expect(layer.namespace).toEqual '::Ethernet::ARP'
    expect(layer.name).toEqual 'ARP'
    expect(layer.summary).toEqual '[REQUEST] 00:10:38:23:14:b0-192.168.150.1 -> 00:00:00:00:00:00-192.168.150.31'
    expect(layer.attrs.htype.toString()).toEqual "Ethernet (1)"
    expect(layer.attrs.ptype.toString()).toEqual "IPv4 (2048)"
    expect(layer.attrs.hlen).toEqual 6
    expect(layer.attrs.plen).toEqual 4
    expect(layer.attrs.operation.toString()).toEqual "request (1)"
    expect(layer.attrs.sha.toString()).toEqual "00:10:38:23:14:b0"
    expect(layer.attrs.spa.toString()).toEqual "192.168.150.1"
    expect(layer.attrs.tha.toString()).toEqual "00:00:00:00:00:00"
    expect(layer.attrs.tpa.toString()).toEqual "192.168.150.31"
    expect(packet.layers['::<Ethernet>'].layers['::Ethernet::<ARP>'].attrs.padding.length).toEqual 18
