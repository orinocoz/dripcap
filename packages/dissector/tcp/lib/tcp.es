import {Layer, Buffer, NetStream} from 'dripcap';
import IPv4Host from 'dripcap/ipv4/host';
import IPv6Host from 'dripcap/ipv6/host';
import TCPFlags from 'dripcap/tcp/flags';

export default class TCPDissector
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
    layer.name = 'TCP';
    layer.namespace = parentLayer.namespace.replace('<TCP>', 'TCP');

    try {

      assertLength(2);
      let source = parentLayer.payload.readUInt16BE(0, true)
      layer.fields.push({
        name: 'Source port',
        value: source,
        data: parentLayer.payload.slice(0, 2)
      });

      let srcAddr = parentLayer.attrs.src;

      if (srcAddr.constructor.name === 'IPv4Address') {
        layer.attrs.src = new IPv4Host(srcAddr, source);
      } else {
        layer.attrs.src = new IPv6Host(srcAddr, source);
      }

      assertLength(4);
      let destination = parentLayer.payload.readUInt16BE(2, true);
      layer.fields.push({
        name: 'Destination port',
        value: destination,
        data: parentLayer.payload.slice(2, 4)
      });

      let dstAddr = parentLayer.attrs.dst;
      if (dstAddr.constructor.name === 'IPv4Address') {
        layer.attrs.dst = new IPv4Host(dstAddr, destination);
      } else {
        layer.attrs.dst = new IPv6Host(dstAddr, destination);
      }

      assertLength(8);
      let seq = parentLayer.payload.readUInt32BE(4, true);
      layer.fields.push({
        name: 'Sequence number',
        attr: 'seq',
        data: parentLayer.payload.slice(4, 8)
      });
      layer.attrs.seq = seq;

      assertLength(12);
      let ack = parentLayer.payload.readUInt32BE(8, true);
      layer.fields.push({
        name: 'Acknowledgment number',
        attr: 'ack',
        data: parentLayer.payload.slice(8, 12)
      });
      layer.attrs.ack = ack;

      assertLength(13);
      let dataOffset = (parentLayer.payload.readUInt8(12, true) >> 4);
      layer.fields.push({
        name: 'Data offset',
        attr: 'dataOffset',
        data: parentLayer.payload.slice(12, 13)
      });
      layer.attrs.dataOffset = dataOffset;

      assertLength(14);
      let flags = new TCPFlags(parentLayer.payload.readUInt8(13, true) |
        ((parentLayer.payload.readUInt8(12, true) & 0x1) << 8));

      layer.fields.push({
        name: 'Flags',
        attr: 'flags',
        data: parentLayer.payload.slice(12, 14),
        fields: [{
          name: 'NS',
          value: flags.get('NS'),
          data: parentLayer.payload.slice(12, 13)
        }, {
          name: 'CWR',
          value: flags.get('CWR'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'ECE',
          value: flags.get('ECE'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'URG',
          value: flags.get('URG'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'ACK',
          value: flags.get('ACK'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'PSH',
          value: flags.get('PSH'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'RST',
          value: flags.get('RST'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'SYN',
          value: flags.get('SYN'),
          data: parentLayer.payload.slice(13, 14)
        }, {
          name: 'FIN',
          value: flags.get('FIN'),
          data: parentLayer.payload.slice(13, 14)
        }]
      });
      layer.attrs.flags = flags;

      assertLength(16);
      layer.fields.push({
        name: 'Window size',
        attr: 'window',
        data: parentLayer.payload.slice(14, 16)
      });
      layer.attrs.window = parentLayer.payload.readUInt16BE(14, true);

      assertLength(18);
      layer.fields.push({
        name: 'Checksum',
        attr: 'checksum',
        data: parentLayer.payload.slice(16, 18)
      });
      layer.attrs.checksum = parentLayer.payload.readUInt16BE(16, true);

      assertLength(20);
      layer.fields.push({
        name: 'Urgent pointer',
        attr: 'urgent',
        data: parentLayer.payload.slice(18, 20)
      })
      layer.attrs.urgent = parentLayer.payload.readUInt16BE(18, true);

      assertLength(dataOffset * 4);
      let optionItems = [];
      let option = {
        name: 'Options',
        data: parentLayer.payload.slice(20, dataOffset * 4),
        fields: []
      };

      let optionData = parentLayer.payload.slice(0, dataOffset * 4);
      let optionOffset = 20;

      function checkLength(payload, offset, len) {
        if (!(payload.length >= offset + len && payload[offset + 1] === len)) {
          throw new Error('invalid option');
        }
      }

      while (optionData.length > optionOffset) {
        switch (optionData[optionOffset]) {
          case 0:
            optionOffset = optionData.length;
            break;

          case 1:
            option.fields.push({
              name: 'NOP',
              value: '',
              data: parentLayer.payload.slice(optionOffset, optionOffset + 1)
            });
            optionOffset++;
            break;

          case 2:
            checkLength(optionData, optionOffset, 4);
            optionItems.push('Maximum segment size');
            option.fields.push({
              name: 'Maximum segment size',
              value: parentLayer.payload.readUInt16BE(optionOffset + 2, true),
              data: parentLayer.payload.slice(optionOffset, optionOffset+4)
            });
            optionOffset += 4;
            break;

          case 3:
            checkLength(optionData, optionOffset, 3);
            optionItems.push('Window scale');
            option.fields.push({
              name: 'Window scale',
              value: parentLayer.payload.readUInt8(optionOffset + 2, true),
              data: parentLayer.payload.slice(optionOffset, optionOffset+3)
            });
            optionOffset += 3;
            break;

          case 4:
            checkLength(optionData, optionOffset, 2);
            optionItems.push('Selective ACK permitted');
            option.fields.push({
              name: 'Selective ACK permitted',
              value: '',
              data: parentLayer.payload.slice(optionOffset, optionOffset+2)
            });
            optionOffset += 2;
            break;

          // TODO: https://tools.ietf.org/html/rfc2018
          case 5:
            checkLength(optionData, optionOffset, 2)
            let length = parentLayer.payload.readUInt8(optionOffset + 1, true);
            checkLength(optionData.length, optionOffset, length);
            optionItems.push('Selective ACK');
            option.fields.push({
              name: 'Selective ACK',
              value: parentLayer.payload.slice(optionOffset + 2, optionOffset + length),
              data: parentLayer.payload.slice(optionOffset, optionOffset+length)
            });

            optionOffset += length;
            break;

          case 8:
            checkLength(optionData, optionOffset, 10);
            let mt = parentLayer.payload.readUInt32BE(optionOffset + 2, true);
            let et = parentLayer.payload.readUInt32BE(optionOffset + 2, true);
            optionItems.push('Timestamps');
            option.fields.push({
              name: 'Timestamps',
              value: `${mt} - ${et}`,
              data: parentLayer.payload.slice(optionOffset, optionOffset+10),
              fields: [{
                name: 'My timestamp',
                value: mt,
                data: parentLayer.payload.slice(optionOffset+2, optionOffset+6)
              }, {
                name: 'Echo reply timestamp',
                value: et,
                data: parentLayer.payload.slice(optionOffset+6, optionOffset+10)
              }]
            });
            optionOffset += 10;
            break;

          default:
            throw new Error('unknown option');
        }
      }

      option.value = optionItems.join(',');
      layer.fields.push(option);

      layer.payload = parentLayer.payload.slice(dataOffset * 4);

      layer.fields.push({
        name: 'Payload',
        value: layer.payload,
        data: layer.payload
      });

      let stream = new NetStream('TCP Stream', parentLayer.namespace, layer.attrs.src + '/' + layer.attrs.dst);
      if (flags.get('SYN') && flags.get('ACK')) {
        stream.start();
      } else if (flags.get('FIN') && flags.get('ACK')) {
        stream.end();
      }
      stream.data = layer.payload;
      layer.streams.push(stream);

      layer.summary = `${layer.attrs.src} -> ${layer.attrs.dst} seq:${seq} ack:${ack}`;

    } catch (err) {
      layer.error = err.message;
    }

    parentLayer.layers[layer.namespace] = layer;
  }
}
