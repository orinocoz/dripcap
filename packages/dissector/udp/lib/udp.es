import {Layer, Buffer} from 'dripcap';
import IPv4Host from 'dripcap/ipv4/host';
import IPv6Host from 'dripcap/ipv6/host';

export default class UDPDissector
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
    layer.name = 'UDP';
    layer.namespace = parentLayer.namespace.replace('<UDP>', 'UDP');

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

      assertLength(6);
      let length = parentLayer.payload.readUInt16BE(4, true)
      layer.fields.push({
        name: 'Length',
        attr: 'length',
        data: parentLayer.payload.slice(4, 6)
      });
      layer.attrs.length = length;

      assertLength(8);
      let checksum = parentLayer.payload.readUInt16BE(6, true)
      layer.fields.push({
        name: 'Checksum',
        attr: 'checksum',
        data: parentLayer.payload.slice(6, 8)
      });
      layer.attrs.checksum = checksum;

      assertLength(length);
      layer.payload = parentLayer.payload.slice(8, length);

      layer.fields.push({
        name: 'Payload',
        value: layer.payload,
        data: layer.payload
      });

      layer.summary = `${layer.attrs.src} -> ${layer.attrs.dst}`;

    } catch (err) {
      layer.error = err.message;
    }

    parentLayer.layers[layer.namespace] = layer;
    return true;
  }
}
