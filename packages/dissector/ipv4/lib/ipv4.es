import {Layer, Buffer} from 'dripcap';
import MACAddress from 'dripcap/mac';
import ProtocolEnum from 'dripcap/ipv4/protocol';
import IPv4Address from 'dripcap/ipv4/addr';
import FieldFlags from 'dripcap/ipv4/fields';

export default class IPv4Dissector
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
    layer.name = 'IPv4';
    layer.namespace = '::Ethernet::IPv4';

    try {
      assertLength(1);
      layer.fields.push({
        name: 'Version',
        attr: 'version',
        data: parentLayer.payload.slice(0, 1),
      });
      layer.attrs.version = parentLayer.payload.readUInt8(0, true) >> 4;

      layer.fields.push({
        name: 'Internet Header Length',
        attr: 'headerLength',
        data: parentLayer.payload.slice(0, 1),
      });
      layer.attrs.headerLength = parentLayer.payload.readUInt8(0, true) & 0b00001111;

      assertLength(2);
      layer.fields.push({
        name: 'Type of service',
        attr: 'type',
        data: parentLayer.payload.slice(1, 2),
      });
      layer.attrs.type = parentLayer.payload.readUInt8(1, true);

      assertLength(4);
      let totalLength = parentLayer.payload.readUInt16BE(2, true);
      layer.fields.push({
        name: 'Total Length',
        attr: 'totalLength',
        data: parentLayer.payload.slice(2, 4),
      });
      layer.attrs.totalLength = totalLength;

      assertLength(6);
      layer.fields.push({
        name: 'Identification',
        attr: 'id',
        data: parentLayer.payload.slice(4, 6),
      });
      layer.attrs.id = parentLayer.payload.readUInt16BE(4, true);

      assertLength(7);
      let flags = new FieldFlags((parentLayer.payload.readUInt8(6, true) >> 5) & 0x7);
      layer.fields.push({
        name: 'Flags',
        attr: 'flags',
        data: parentLayer.payload.slice(6, 7),
        fields: [{
          name: 'Reserved',
          value: flags.get('Reserved'),
          data: parentLayer.payload.slice(6, 7),
        }, {
          name: 'Don\'t Fragment',
          value: flags.get('Don\'t Fragment'),
          data: parentLayer.payload.slice(6, 7),
        }, {
          name: 'More Fragments',
          value: flags.get('More Fragments'),
          data: parentLayer.payload.slice(6, 7),
        }]
      });
      layer.attrs.flags = flags;

      layer.fields.push({
        name: 'Fragment Offset',
        attr: 'fragmentOffset',
        data: parentLayer.payload.slice(6, 8),
      });
      layer.attrs.fragmentOffset = parentLayer.payload.readUInt8(6, true) & 0b0001111111111111;

      assertLength(9);
      layer.fields.push({
        name: 'TTL',
        attr: 'ttl',
        data: parentLayer.payload.slice(8, 9),
      });
      layer.attrs.ttl = parentLayer.payload.readUInt8(8, true);

      assertLength(10);
      let protocol = new ProtocolEnum(parentLayer.payload.readUInt8(9, true));

      layer.fields.push({
        name: 'Protocol',
        attr: 'protocol',
        data: parentLayer.payload.slice(9, 10),
      });
      layer.attrs.protocol = protocol;

      if (protocol.known) {
        layer.namespace = `::Ethernet::IPv4::<${protocol.name}>`;
      }

      assertLength(12);
      layer.fields.push({
        name: 'Header Checksum',
        attr: 'checksum',
        data: parentLayer.payload.slice(10, 12),
      });
      layer.attrs.checksum = parentLayer.payload.readUInt16BE(10, true);

      assertLength(16);
      let source = new IPv4Address(parentLayer.payload.slice(12, 16));
      layer.fields.push({
        name: 'Source IP Address',
        attr: 'src',
        data: parentLayer.payload.slice(12, 16),
      });
      layer.attrs.src = source;

      assertLength(20);
      let destination = new IPv4Address(parentLayer.payload.slice(16, 20));
      layer.fields.push({
        name: 'Destination IP Address',
        attr: 'dst',
        data: parentLayer.payload.slice(16, 20),
      });
      layer.attrs.dst = destination;

      assertLength(totalLength);
      layer.payload = parentLayer.payload.slice(20, totalLength);

      layer.fields.push({
        name : 'Payload',
        value : layer.payload,
        data : layer.payload
      });

      layer.summary = `${source} -> ${destination}`;
      if (protocol.known) {
        layer.summary = `[${protocol.name}] ` + layer.summary;
      }

    } catch (err) {
      layer.error = err.message;
    }

    parentLayer.layers[layer.namespace] = layer;
  }
}
