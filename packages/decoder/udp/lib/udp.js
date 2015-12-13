import {IPv4Host, IPv6Host, IPv4Address, Flags} from 'dripper/type'

export default class UDPDecoder {
  constructor() {
    this.lowerLayers = [
      '::Ethernet::IPv4::<UDP>',
      '::Ethernet::IPv6::<UDP>'
    ]
  }

  analyze(packet) {
    return new Promise((resolve, reject) => {
      let slice = packet.layers[2].payload
      let payload = slice.apply(packet.payload)

      let layer = {
        name: 'UDP',
        aliases: [],
        namespace: packet.layers[2].namespace.replace('<UDP>', 'UDP'),
        fields: [],
        attrs: {}
      }

      let assertLength = (len) => {
        if (payload.length < len) {
          throw new Error('too short frame')
        }
      }

      try {
        assertLength(2)
        let source = payload.readUInt16BE(0, true)
        layer.fields.push({
          name: 'Source port',
          value: source,
          range: slice.slice(0, 2)
        })

        let srcAddr = packet.layers[2].attrs.src
        if (srcAddr instanceof IPv4Address)
          layer.attrs.src = new IPv4Host(srcAddr, source)
        else
          layer.attrs.src = new IPv6Host(srcAddr, source)

        assertLength(4)
        let destination = payload.readUInt16BE(2, true)
        layer.fields.push({
          name: 'Destination port',
          value: destination,
          range: slice.slice(2, 4)
        })

        let dstAddr = packet.layers[2].attrs.dst
        if (dstAddr instanceof IPv4Address)
          layer.attrs.dst = new IPv4Host(dstAddr, destination)
        else
          layer.attrs.dst = new IPv6Host(dstAddr, destination)

        assertLength(6)
        let length = payload.readUInt16BE(4, true)
        layer.fields.push({
          name: 'Length',
          attr: 'length',
          range: slice.slice(4, 6)
        })
        layer.attrs.length = length

        assertLength(8)
        let checksum = payload.readUInt16BE(6, true)
        layer.fields.push({
          name: 'Checksum',
          attr: 'checksum',
          range: slice.slice(6, 8)
        })

        layer.attrs.checksum = checksum

        assertLength(length)
        layer.payload = slice.slice(8, 8 + length)

        layer.fields.push({
          name: 'Payload',
          value: layer.payload,
          range: layer.payload
        })

        layer.summary = `${layer.attrs.src} -> ${layer.attrs.dst}`
      } catch (e) {
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
