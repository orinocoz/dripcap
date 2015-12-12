import fs from 'fs'
import EthernetDecoder from '../../ethernet/lib/ethernet'
import IPv6Decoder from '../lib/ipv6'
import { PayloadSlice } from 'dripper/type'

describe("IPv6", () => {
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
      (new IPv6Decoder()).analyze(packet).then(() => done())
    })
  })

  it("decodes an IPv6 frame from an ethernet frame", () => {
    let layer = packet.layers[2]
    expect(layer.namespace).toEqual('::Ethernet::IPv6::<ICMP>')
    expect(layer.name).toEqual('IPv6')
    expect(layer.summary).toEqual('[ICMP] fe80::7627:eaff:fe0f:1895 -> ff02::1:ff0f:1895')
    expect(layer.attrs.version).toEqual(6)
    expect(layer.attrs.trafficClass).toEqual(0)
    expect(layer.attrs.flowLevel).toEqual(0)
    expect(layer.attrs.payloadLength).toEqual(32)
    expect(layer.attrs.protocol.toString()).toEqual('ICMP (58)')
    expect(layer.attrs.hopLimit).toEqual(1)
    expect(layer.attrs.dst.toString()).toEqual('ff02::1:ff0f:1895')
    expect(layer.attrs.src.toString()).toEqual('fe80::7627:eaff:fe0f:1895')
  })
})
