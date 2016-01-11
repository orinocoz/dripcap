{MACAddress, IPv4Address, Enum} = require('dripcap/type')

class DNSDecoder
  lowerLayers: -> [
    '::Ethernet::IPv4::UDP'
    '::Ethernet::IPv6::UDP'
  ]

  analyze: (packet, parentLayer) ->
    new Promise (resolve, reject) ->

      slice = parentLayer.payload
      payload = slice.apply packet.payload

      layer =
        name: 'DNS'
        aliases: []
        namespace: parentLayer.namespace + '::DNS'
        fields: []
        attrs: {}

      assertLength = (len) ->
        throw new Error('too short frame') if payload.length < len

      try
        assertLength(12)
        id = payload.readUInt16BE(0, true)
        flags0 = payload.readUInt8(2, true)
        flags1 = payload.readUInt8(3, true)
        qr = !!(flags0 >> 7)

        opTable =
          0: 'QUERY'
          1: 'IQUERY'
          2: 'STATUS'
          4: 'NOTIFY'
          5: 'UPDATE'
        opcode = new Enum opTable, (flags0 >> 3) & 0b00001111
        throw new Error('wrong DNS opcode') unless opcode.known

        aa = !!((flags0 >> 2) & 1)
        tc = !!((flags0 >> 1) & 1)
        rd = !!((flags0 >> 0) & 1)
        ra = !!(flags1 >> 7)
        throw new Error('reserved bits must be zero') if flags1 & 0b01110000

        rTable =
          0: 'No Error'
          1: 'Format Error'
          2: 'Server Failure'
          3: 'Name Error'
          4: 'Not Implemented'
          5: 'Refused'
          6: 'YX Domain'
          7: 'YX RR Set'
          8: 'NX RR Set'
          9: 'Not Auth'
          10: 'Not Zone'
        rcode = new Enum rTable, flags1 & 0b00001111
        throw new Error('wrong DNS rcode') unless rcode.known

        qdCount = payload.readUInt16BE(4, true)
        anCount = payload.readUInt16BE(6, true)
        nsCount = payload.readUInt16BE(8, true)
        arCount = payload.readUInt16BE(10, true)

        layer.fields.push
          name: 'ID'
          attr: 'id'
          range: slice.slice(0, 2)
        layer.attrs.id = id

        layer.fields.push
          name: 'Query/Response Flag'
          attr: 'qr'
          range: slice.slice(2, 3)
        layer.attrs.qr = qr

        layer.fields.push
          name: 'Operation Code'
          attr: 'opcode'
          range: slice.slice(2, 3)
        layer.attrs.opcode = opcode

        layer.fields.push
          name: 'Authoritative Answer Flag'
          attr: 'aa'
          range: slice.slice(2, 3)
        layer.attrs.aa = aa

        layer.fields.push
          name: 'Truncation Flag'
          attr: 'tc'
          range: slice.slice(2, 3)
        layer.attrs.tc = tc

        layer.fields.push
          name: 'Recursion Desired'
          attr: 'rd'
          range: slice.slice(2, 3)
        layer.attrs.rd = rd

        layer.fields.push
          name: 'Recursion Available'
          attr: 'ra'
          range: slice.slice(3, 4)
        layer.attrs.ra = ra

        layer.fields.push
          name: 'Response Code'
          attr: 'rcode'
          range: slice.slice(3, 4)
        layer.attrs.rcode = rcode

        layer.fields.push
          name: 'Question Count'
          attr: 'qdCount'
          range: slice.slice(4, 6)
        layer.attrs.qdCount = qdCount

        layer.fields.push
          name: 'Answer Record Count'
          attr: 'anCount'
          range: slice.slice(6, 8)
        layer.attrs.anCount = anCount

        layer.fields.push
          name: 'Authority Record Count'
          attr: 'nsCount'
          range: slice.slice(8, 10)
        layer.attrs.nsCount = nsCount

        layer.fields.push
          name: 'Additional Record Count'
          attr: 'arCount'
          range: slice.slice(10, 12)
        layer.attrs.arCount = arCount

      catch e
        reject()
        return

      try
        layer.payload = slice.slice(12)
        layer.fields.push
          name: 'Payload'
          value: layer.payload
          range: layer.payload

        layer.summary = "[#{opcode.name}] [#{rcode.name}] qd:#{qdCount} an:#{anCount} ns:#{nsCount} ar:#{arCount}"
      catch e
        layer.error = e.message

      parentLayer.layers =
        "#{layer.namespace}": layer

      if layer.error?
        reject(parentLayer)
      else
        resolve(parentLayer)

module.exports = DNSDecoder
