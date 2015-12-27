fs = require('fs')
EthernetDecoder = require('../../ethernet/lib/ethernet')
IPv4Decoder = require('../../ipv4/lib/ipv4')
TCPDecoder = require('../lib/tcp')
{PayloadSlice} = require('dripcap/type')

describe "TCP", ->
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
    (new EthernetDecoder()).analyze(packet).then (packet) ->
      (new IPv4Decoder()).analyze(packet).then (packet) ->
        (new TCPDecoder()).analyze(packet).then -> done()

  it "decodes an tcp frame from an ipv4 frame", ->
    layer = packet.layers[3]
    expect(layer.namespace).toEqual '::Ethernet::IPv4::TCP'
    expect(layer.name).toEqual 'TCP'
    expect(layer.summary).toEqual '173.194.117.168:443 -> 192.168.150.35:44700 seq:1651424476 ack:1509819690'
    expect(layer.attrs.src.toString()).toEqual '173.194.117.168:443'
    expect(layer.attrs.dst.toString()).toEqual '192.168.150.35:44700'
    expect(layer.attrs.seq).toEqual 1651424476
    expect(layer.attrs.ack).toEqual 1509819690
    expect(layer.attrs.dataOffset).toEqual 8
    expect(layer.attrs.flags.toString()).toEqual 'ACK, PSH (24)'
    expect(layer.attrs.window).toEqual 341
    expect(layer.attrs.checksum).toEqual 39726
    expect(layer.attrs.urgent).toEqual 0
