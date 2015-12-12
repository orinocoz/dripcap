import fs from 'fs'
import EthernetDecoder from '../../ethernet/lib/ethernet'
import IPv4Decoder from '../../ipv4/lib/ipv4'
import UDPDecoder from '../lib/udp'
import { PayloadSlice } from 'dripper/type'

describe("UDP", () => {
  let payload = fs.readFileSync(__dirname + '/data.bin')

  let packet = {
    timestamp: new Date(),
    interface: 'eth0',
    options: {},
    payload: payload,
    layers: [{
      namespace: '::<Ethernet>',
      name: 'Raw Frame',
      payload: new PayloadSlice(0, payload.length),
      summary: ''
    }]
  }

  beforeEach((done) => {
    (new EthernetDecoder()).analyze(packet).then((packet) => {
      (new IPv4Decoder()).analyze(packet).then((packet) => {
        (new UDPDecoder()).analyze(packet).then(() => done())
      })
    })
  })

  it("decodes a udp frame from an ipv4 frame", () => {
    let layer = packet.layers[3]
    expect(layer.namespace).toEqual('::Ethernet::IPv4::UDP')
    expect(layer.name).toEqual('UDP')
    expect(layer.summary).toEqual('192.168.150.35:9466 -> 8.8.8.8:53')
    expect(layer.attrs.src.toString()).toEqual('192.168.150.35:9466')
    expect(layer.attrs.dst.toString()).toEqual('8.8.8.8:53')
    expect(layer.attrs.length).toEqual(56)
    expect(layer.attrs.checksum).toEqual(19264)
  })
})
