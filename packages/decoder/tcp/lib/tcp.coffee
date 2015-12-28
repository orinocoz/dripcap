{IPv4Host, IPv6Host, IPv4Address, Flags} = require('dripcap/type')

class TCPDecoder
  lowerLayers: ->
    [
      '::Ethernet::IPv4::<TCP>'
      '::Ethernet::IPv6::<TCP>'
    ]

  analyze: (packet) ->
    new Promise (resolve, reject) ->

      slice = packet.layers[2].payload
      payload = slice.apply packet.payload

      layer =
        name: 'TCP'
        aliases: []
        namespace: packet.layers[2].namespace.replace('<TCP>', 'TCP')
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

        assertLength(8)
        seq = payload.readUInt32BE(4, true)
        layer.fields.push
          name: 'Sequence number'
          attr: 'seq'
          range: slice.slice(4, 8)
        layer.attrs.seq = seq

        assertLength(12)
        ack = payload.readUInt32BE(8, true)
        layer.fields.push
          name: 'Acknowledgment number'
          attr: 'ack'
          range: slice.slice(8, 12)
        layer.attrs.ack = ack

        assertLength(13)
        dataOffset = payload.readUInt8(12, true) >> 4
        layer.fields.push
          name: 'Data offset'
          attr: 'dataOffset'
          range: slice.slice(12, 13)
        layer.attrs.dataOffset = dataOffset

        assertLength(14)

        table =
          'NS': 0x1 << 8
          'CWR': 0x1 << 7
          'ECE': 0x1 << 6
          'URG': 0x1 << 5
          'ACK': 0x1 << 4
          'PSH': 0x1 << 3
          'RST': 0x1 << 2
          'SYN': 0x1 << 1
          'FIN': 0x1 << 0

        flags = new Flags table, payload.readUInt8(13, true) |
          ((payload.readUInt8(12, true) & 0x1) << 8)
        layer.fields.push
          name: 'Flags'
          attr: 'flags'
          range: slice.slice(12, 14)
          fields: [
            name: 'NS'
            value: flags.get 'NS'
            range: slice.slice(12, 13)
          ,
            name: 'CWR'
            value: flags.get 'CWR'
            range: slice.slice(13, 14)
          ,
            name: 'ECE'
            value: flags.get 'ECE'
            range: slice.slice(13, 14)
          ,
            name: 'URG'
            value: flags.get 'URG'
            range: slice.slice(13, 14)
          ,
            name: 'ACK'
            value: flags.get 'ACK'
            range: slice.slice(13, 14)
          ,
            name: 'PSH'
            value: flags.get 'PSH'
            range: slice.slice(13, 14)
          ,
            name: 'RST'
            value: flags.get 'RST'
            range: slice.slice(13, 14)
          ,
            name: 'SYN'
            value: flags.get 'SYN'
            range: slice.slice(13, 14)
          ,
            name: 'FIN'
            value: flags.get 'FIN'
            range: slice.slice(13, 14)
          ]
        layer.attrs.flags = flags

        assertLength(16)
        layer.fields.push
          name: 'Window size'
          attr: 'window'
          range: slice.slice(14, 16)
        layer.attrs.window = payload.readUInt16BE(14, true)

        assertLength(18)
        layer.fields.push
          name: 'Checksum'
          attr: 'checksum'
          range: slice.slice(16, 18)
        layer.attrs.checksum = payload.readUInt16BE(16, true)

        assertLength(20)
        layer.fields.push
          name: 'Urgent pointer'
          attr: 'urgent'
          range: slice.slice(18, 20)
        layer.attrs.urgent = payload.readUInt16BE(18, true)

        assertLength(dataOffset * 4)
        optionItems = []
        option =
          name: 'Options'
          range: slice.slice(20, dataOffset * 4)
          fields: []

        optionData = payload.slice(0, dataOffset * 4)
        optionOffset = 20

        checkLength = (payload, offset, len) ->
          unless payload.length >= offset + len && payload[offset + 1] == len
            throw new Error 'invalid option'

        try
          while optionData.length > optionOffset
            switch optionData[optionOffset]
              when 0
                optionOffset = optionData.length

              when 1
                option.fields.push
                  name: 'NOP'
                  value: ''
                  range: slice.slice(optionOffset, optionOffset+1)
                optionOffset++

              when 2
                checkLength(optionData, optionOffset, 4)
                optionItems.push 'Maximum segment size'
                option.fields.push
                  name: 'Maximum segment size'
                  value: payload.readUInt16BE(optionOffset + 2, true)
                  range: slice.slice(optionOffset, optionOffset+4)
                optionOffset += 4

              when 3
                checkLength(optionData, optionOffset, 3)
                optionItems.push 'Window scale'
                option.fields.push
                  name: 'Window scale'
                  value: payload.readUInt8(optionOffset + 2, true)
                  range: slice.slice(optionOffset, optionOffset+3)
                optionOffset += 3

              when 4
                checkLength(optionData, optionOffset, 2)
                optionItems.push 'Selective ACK permitted'
                option.fields.push
                  name: 'Selective ACK permitted'
                  value: ''
                  range: slice.slice(optionOffset, optionOffset+2)
                optionOffset += 2

              #TODO: https://tools.ietf.org/html/rfc2018
              when 5
                checkLength(optionData, optionOffset, 2)
                length = payload.readUInt8(optionOffset + 1, true)
                checkLength(optionData.length, optionOffset, length)
                optionItems.push 'Selective ACK'
                option.fields.push
                  name: 'Selective ACK'
                  value: payload.slice(optionOffset + 2, optionOffset + length)
                  range: slice.slice(optionOffset, optionOffset+length)
                optionOffset += length

              when 8
                checkLength(optionData, optionOffset, 10)
                mt = payload.readUInt32BE(optionOffset + 2, true)
                et = payload.readUInt32BE(optionOffset + 2, true)
                optionItems.push 'Timestamps'
                option.fields.push
                  name: 'Timestamps'
                  value: "#{mt} - #{et}"
                  range: slice.slice(optionOffset, optionOffset+10)
                  fields: [
                    name: 'My timestamp'
                    value: mt
                    range: slice.slice(optionOffset+2, optionOffset+6)
                  ,
                    name: 'Echo reply timestamp'
                    value: et
                    range: slice.slice(optionOffset+6, optionOffset+10)
                  ]
                optionOffset += 10

              else
                throw new Error 'unknown option'

        option.value = optionItems.join ','
        layer.fields.push option

        layer.payload = slice.slice(dataOffset * 4)

        layer.fields.push
          name: 'Payload'
          value: layer.payload
          range: layer.payload

        layer.summary = "#{layer.attrs.src} -> #{layer.attrs.dst} seq:#{seq} ack:#{ack}"

      catch e
        layer.error = e.message

      packet.layers.push layer

      if layer.error?
        reject(packet)
      else
        resolve(packet)

module.exports = TCPDecoder
