{MACAddress, Enum} = require('dripcap/type')

class EthernetDecoder
  lowerLayers: ->
    ['::<Ethernet>']

  analyze: (packet) ->
    new Promise (resolve, reject) ->

      slice = packet.layers[0].payload
      payload = slice.apply packet.payload

      layer =
        name: 'Ethernet'
        aliases: ['eth']
        namespace: '::Ethernet'
        fields: []
        attrs: {}

      assertLength = (len) ->
        throw new Error('too short frame') if payload.length < len

      try
        assertLength(6)
        destination = new MACAddress payload.slice(0, 6)
        layer.fields.push
          name: 'MAC destination'
          attr: 'dst'
          range: slice.slice(0, 6)
        layer.attrs.dst = destination

        assertLength(12)
        source = new MACAddress payload.slice(6, 12)
        layer.fields.push
          name: 'MAC source'
          attr: 'src'
          range: slice.slice(6, 12)
        layer.attrs.src = source

        assertLength(14)

        type = payload.readUInt16BE(12, true)
        if type <= 1500
          layer.fields.push
            name: 'Length'
            value: type
            range: slice.slice(12, 14)
        else
          table =
            0x0800: 'IPv4'
            0x0806: 'ARP'
            0x0842: 'WoL'
            0x809B:	'AppleTalk'
            0x80F3:	'AARP'
            0x86DD: 'IPv6'

          etherType = new Enum table, payload.readUInt16BE(12, true)

          layer.fields.push
            name: 'EtherType'
            attr: 'etherType'
            range: slice.slice(12, 14)
          layer.attrs.etherType = etherType

          layer.namespace = "::Ethernet::<#{etherType.name}>" if etherType.known

        layer.payload = slice.slice(14)

        layer.fields.push
          name: 'Payload'
          value: layer.payload
          range: layer.payload

        layer.summary =
          if layer.attrs.etherType?
            "[#{etherType.name}] #{source} -> #{destination}"
          else
            "#{source} -> #{destination}"

      catch e
        layer.error = e.message

      packet.layers.push layer

      if layer.error?
        reject(packet)
      else
        resolve(packet)

module.exports = EthernetDecoder
