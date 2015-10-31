{IPv4Host, IPv6Host, IPv4Address, Flags} = require('dripper/type')

class UDPDecoder
  constructor: ->
    @lowerLayers = [
      '::Ethernet::IPv4::<UDP>'
      '::Ethernet::IPv6::<UDP>'
    ]

  analyze: (packet) ->
    new Promise (resolve, reject) ->

      slice = packet.layers[2].payload
      payload = slice.apply packet.payload

      layer =
        name: 'UDP'
        aliases: []
        namespace: packet.layers[2].namespace.replace('<UDP>', 'UDP')
        fields: []
        attrs: {}

      assertLength = (len) ->
        throw new Error('too short frame') if payload.length < len

      try
        assertLength(2)
        source = payload.readUInt16BE(0, true)
        layer.fields.push
          name: 'Source port'
          value: source
          range: slice.slice(0, 2)

        srcAddr = packet.layers[2].attrs.src
        layer.attrs.src =
          if srcAddr instanceof IPv4Address
            new IPv4Host(srcAddr, source)
          else
            new IPv6Host(srcAddr, source)

        assertLength(4)
        destination = payload.readUInt16BE(2, true)
        layer.fields.push
          name: 'Destination port'
          value: destination
          range: slice.slice(2, 4)

        dstAddr = packet.layers[2].attrs.dst
        layer.attrs.dst =
          if dstAddr instanceof IPv4Address
            new IPv4Host(dstAddr, destination)
          else
            new IPv6Host(dstAddr, destination)

        assertLength(6)
        length = payload.readUInt16BE(4, true)
        layer.fields.push
          name: 'Length'
          attr: 'length'
          range: slice.slice(4, 6)
        layer.attrs.length = length

        assertLength(8)
        checksum = payload.readUInt16BE(6, true)
        layer.fields.push
          name: 'Checksum'
          attr: 'checksum'
          range: slice.slice(6, 8)
        layer.attrs.checksum = checksum

        assertLength(length)
        layer.payload = slice.slice(8, 8 + length)

        layer.fields.push
          name: 'Payload'
          value: layer.payload
          range: layer.payload

        layer.summary = "#{layer.attrs.src} -> #{layer.attrs.dst}"

      catch e
        layer.error = e.message

      packet.layers.push layer

      if layer.error?
        reject(packet)
      else
        resolve(packet)

module.exports = UDPDecoder
