import {MACAddress, Enum} from 'dripper/type'

export default class EthernetDecoder {
  constructor() {
    this.lowerLayers = ['::<Ethernet>']
  }

  analyze(packet) {
    return new Promise((resolve, reject) => {
      let slice = packet.layers[0].payload
      let payload = slice.apply(packet.payload)

      let layer = {
        name: 'Ethernet',
        aliases: ['eth'],
        namespace: '::Ethernet',
        fields: [],
        attrs: {}
      }

      let assertLength = (len) => {
        if (payload.length < len)
          throw new Error('too short frame')
      }

      try {
        assertLength(6)
        let destination = new MACAddress(payload.slice(0, 6))
        layer.fields.push({
          name: 'MAC destination',
          attr: 'dst',
          range: slice.slice(0, 6)
        })
        layer.attrs.dst = destination

        assertLength(12)
        let source = new MACAddress(payload.slice(6, 12))
        layer.fields.push({
          name: 'MAC source',
          attr: 'src',
          range: slice.slice(6, 12)
        })
        layer.attrs.src = source

        assertLength(14)

        let table = {
          0x0800: 'IPv4',
          0x0806: 'ARP',
          0x0842: 'WoL',
          0x809B:	'AppleTalk',
          0x80F3:	'AARP',
          0x86DD: 'IPv6'
        }

        let etherType = new Enum(table, payload.readUInt16BE(12, true))

        layer.fields.push({
          name: 'EtherType',
          attr: 'etherType',
          range: slice.slice(12, 14)
        })
        layer.attrs.etherType = etherType

        if (etherType.known)
          layer.namespace = `::Ethernet::<${etherType.name}>`

        layer.payload = slice.slice(14)

        layer.fields.push({
          name: 'Payload',
          value: layer.payload,
          range: layer.payload
        })

        layer.summary = `[${etherType.name}] ${source} -> ${destination}`

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
