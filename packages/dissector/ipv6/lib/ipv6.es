import {Layer, Buffer} from 'dripcap';
import MACAddress from 'dripcap/mac';
import ProtocolEnum from 'dripcap/ipv6/protocol';
import IPv6Address from 'dripcap/ipv6/addr';

export default class IPv6Dissector
{
  constructor(options)
  {
  }

  analyze(packet, parentLayer)
  {
    function assertLength(len)
    {
      if (parentLayer.payload.length < len) {
        throw new Error('too short frame');
      }
    }

    let layer = new Layer();
    layer.name = 'IPv6';
    layer.namespace = '::Ethernet::IPv6';

    try {
      assertLength(1);
      layer.fields.push({
        name: 'Version',
        attr: 'version',
        data: parentLayer.payload.slice(0, 1),
      });
      layer.attrs.version = parentLayer.payload.readUInt8(0, true) >> 4;

      assertLength(2);
      layer.fields.push({
        name: 'Traffic Class',
        attr: 'trafficClass',
        data: parentLayer.payload.slice(0, 2),
      });
      layer.attrs.trafficClass =
        ((parentLayer.payload.readUInt8(0, true) & 0b00001111) << 4) |
        ((parentLayer.payload.readUInt8(1, true) & 0b11110000) >> 4);

      assertLength(4);
      let flowLevel = parentLayer.payload.readUInt16BE(2, true) |
        ((parentLayer.payload.readUInt8(1, true) & 0b00001111) << 16);
      layer.fields.push({
        name: 'Flow Label',
        attr: 'flowLevel',
        data: parentLayer.payload.slice(1, 4),
      });
      layer.attrs.flowLevel = flowLevel;

      assertLength(6);
      let payloadLength = parentLayer.payload.readUInt16BE(4, true);
      layer.fields.push({
        name: 'Payload Length',
        attr: 'payloadLength',
        data: parentLayer.payload.slice(4, 6),
      });
      layer.attrs.payloadLength = payloadLength;

      assertLength(7);
      let nextHeader = parentLayer.payload.readUInt8(6, true);
      let nextHeaderData = parentLayer.payload.slice(6, 7);

      layer.fields.push({
        name: 'Next Header',
        value: new ProtocolEnum(nextHeader),
        data: nextHeaderData,
      });

      assertLength(8);
      layer.fields.push({
        name: 'Hop Limit',
        attr: 'hopLimit',
        data: parentLayer.payload.slice(7, 8),
      });
      layer.attrs.hopLimit = parentLayer.payload.readUInt8(7, true);

      assertLength(24);
      let source = new IPv6Address(parentLayer.payload.slice(8, 24));
      layer.fields.push({
        name: 'Source IP Address',
        attr: 'src',
        data: parentLayer.payload.slice(8, 24)
      });
      layer.attrs.src = source;

      assertLength(40);
      let destination = new IPv6Address(parentLayer.payload.slice(24, 40));
      layer.fields.push({
        name: 'Destination IP Address',
        attr: 'dst',
        data: parentLayer.payload.slice(24, 40)
      });
      layer.attrs.dst = destination;

      if (payloadLength > 0)
        assertLength(payloadLength + 40);

      let offset = 40;
      let ext = true;

      while (ext) {
        let optlen = 0;
        switch(nextHeader) {
          case 0:
          case 60: // Hop-by-Hop Options, Destination Options
            let extLen = (parentLayer.payload.readUInt8(offset + 1, true) + 1) * 8;
            assertLength(offset + extLen);
            let name = (nextHeader == 0) ? 'Hop-by-Hop Options' : 'Destination Options';
            layer.fields.push({
              name: name,
              data: parentLayer.payload.slice(offset, offset + extLen),
              fields: [{
                name: 'Hdr Ext Len',
                value: payload.readUInt8(offset + 1, true),
                note: `(${extLen} bytes)`,
                data: parentLayer.payload.slice(offset + 1, offset + 2)
              }, {
                name: 'Options and Padding',
                value: parentLayer.payload.slice(offset + 2, offset + extLen),
                data: parentLayer.payload.slice(offset + 2, offset + extLen)
              }]
            });
            optlen = extLen;
            break;
          // TODO:
          // case 43  # Routing
          // case 44  # Fragment
          // case 51  # Authentication Header
          // case 50  # Encapsulating Security Payload
          // case 135 # Mobility
          case 59: // No Next Header
          default:
            ext = false
            continue
        }

        nextHeader = parentLayer.payload.readUInt8(offset, true);
        nextHeaderRange = parentLayer.payload.slice(offset, offset + 1);
        layer.fields[layer.fields.length - 1].fields.unshift({
          name: 'Next Header',
          value: new ProtocolEnum(nextHeader),
          data: nextHeaderData
        });

        offset += optlen;
      }

      let protocol = new ProtocolEnum(nextHeader);

      if (protocol.known)
        layer.namespace = `::Ethernet::IPv6::<${protocol.name}>`;

      layer.fields.push({
        name: 'Protocol',
        attr: 'protocol',
        data: nextHeaderData
      });
      layer.attrs.protocol = protocol;

      layer.payload = parentLayer.payload.slice(offset)

      layer.fields.push({
        name: 'Payload',
        value: layer.payload,
        data: layer.payload
      });

      layer.summary = `${source} -> ${destination}`
      if (protocol.known) {
        layer.summary = `[${protocol.name}] ` + layer.summary;
      }

    } catch (err) {
      layer.error = err.message;
    }

    parentLayer.layers[layer.namespace] = layer;
    return true;
  }
}
