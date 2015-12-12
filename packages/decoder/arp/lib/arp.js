import {MACAddress, IPv4Address, Enum} from 'dripper/type'

export default class ARPDecoder {
  constructor() {
    this.lowerLayers = ['::Ethernet::<ARP>']
  }

  analyze(packet) {
    return new Promise((resolve, reject) => {
      let slice = packet.layers[1].payload
      let payload = slice.apply(packet.payload)

      let layer = {
        name: 'ARP',
        aliases: [],
        namespace: '::Ethernet::ARP',
        fields: [],
        attrs: {}
      }

      let assertLength = (len) => {
        if (payload.length < len) {
          throw new Error('too short frame')
        }
      }

      try {
        let table = {
          0x1: 'Ethernet'
        }

        assertLength(2)
        let htype = new Enum(table, payload.readUInt16BE(0, true))
        layer.fields.push({
          name: 'Hardware type',
          attr: 'htype',
          range: slice.slice(0, 2)
        })
        layer.attrs.htype = htype

        table = {
          0x0800: 'IPv4',
          0x86DD: 'IPv6'
        }

        assertLength(4)
        let ptype = new Enum(table, payload.readUInt16BE(2, true))
        layer.fields.push({
          name: 'Protocol type',
          attr: 'ptype',
          range: slice.slice(2, 4)
        })
        layer.attrs.ptype = ptype

        assertLength(5)
        let hlen = payload.readUInt8(4, true)
        layer.fields.push({
          name: 'Hardware length',
          attr: 'hlen',
          range: slice.slice(4, 5)
        })
        layer.attrs.hlen = hlen

        assertLength(6)
        let plen = payload.readUInt8(5, true)
        layer.fields.push({
          name: 'Protocol length',
          attr: 'plen',
          range: slice.slice(5, 6)
        })
        layer.attrs.plen = plen

        table = {
          0x1: 'request',
          0x2: 'reply'
        }

        assertLength(8)
        let operation = new Enum(table, payload.readUInt16BE(6, true))
        layer.fields.push({
          name: 'Operation',
          attr: 'operation',
          range: slice.slice(6, 8)
        })
        layer.attrs.operation = operation

        assertLength(14)
        let sha = new MACAddress(payload.slice(8, 14))
        layer.fields.push({
          name: 'Sender hardware address',
          attr: 'sha',
          range: slice.slice(8, 14)
        })
        layer.attrs.sha = sha

        assertLength(18)
        let spa = new IPv4Address(payload.slice(14, 18))
        layer.fields.push({
          name: 'Sender protocol address',
          attr: 'spa',
          range: slice.slice(14, 18)
        })
        layer.attrs.spa = spa

        assertLength(24)
        let tha = new MACAddress(payload.slice(18, 24))
        layer.fields.push({
          name: 'Target hardware address',
          attr: 'tha',
          range: slice.slice(18, 24)
        })
        layer.attrs.tha = tha

        assertLength(28)
        let tpa = new IPv4Address(payload.slice(24, 28))
        layer.fields.push({
          name: 'Target protocol address',
          attr: 'spa',
          range: slice.slice(24, 28)
        })
        layer.attrs.tpa = tpa

        let ethPadding = packet.layers[1].payload.slice(28)
        packet.layers[1].payload = packet.layers[1].payload.slice(0, 28)
        packet.layers[1].fields.push({
          name: 'Padding',
          attr: 'padding',
          range: ethPadding
        })
        packet.layers[1].attrs.padding = ethPadding

        layer.summary = `[${operation.name.toUpperCase()}] ${sha}-${spa} -> ${tha}-${tpa}`
      } catch(e) {
        layer.error = e.message
      }
      packet.layers.push(layer)

      if (layer.error != null)
        reject(packet)
      else
        resolve(packet)
    })
  }
}
