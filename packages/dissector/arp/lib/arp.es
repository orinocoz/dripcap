import {Layer, Buffer} from 'dripcap';
import MACAddress from 'dripcap/mac';
import HardwareEnum from 'dripcap/arp/hardware';
import ProtocolEnum from 'dripcap/arp/protocol';
import OperationEnum from 'dripcap/arp/operation';
import IPv6Address from 'dripcap/arp/addr';

export default class ARPDissector
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
    layer.name = 'ARP';
    layer.namespace = '::Ethernet::ARP';

    try {

      assertLength(2);
      let htype = new HardwareEnum(parentLayer.payload.readUInt16BE(0, true));
      layer.fields.push({
        name: 'Hardware type',
        attr: 'htype',
        data: parentLayer.payload.slice(0, 2)
      });
      layer.attrs.htype = htype;

      assertLength(4);
      let ptype = new ProtocolEnum(parentLayer.payload.readUInt16BE(2, true));
      layer.fields.push({
        name: 'Protocol type',
        attr: 'ptype',
        data: parentLayer.payload.slice(2, 4)
      });
      layer.attrs.ptype = ptype;

      assertLength(5);
      let hlen = parentLayer.payload.readUInt8(4, true);
      layer.fields.push({
        name: 'Hardware length',
        attr: 'hlen',
        data: parentLayer.payload.slice(4, 5)
      });
      layer.attrs.hlen = hlen;

      assertLength(6);
      let plen = parentLayer.payload.readUInt8(5, true);
      layer.fields.push({
        name: 'Protocol length',
        attr: 'plen',
        data: parentLayer.payload.slice(5, 6)
      });
      layer.attrs.plen = plen;

      assertLength(8);
      let operation = new OperationEnum(parentLayer.payload.readUInt16BE(6, true));
      layer.fields.push({
        name: 'Operation',
        attr: 'operation',
        data: parentLayer.payload.slice(6, 8)
      });
      layer.attrs.operation = operation;

      assertLength(14);
      let sha = new MACAddress(parentLayer.payload.slice(8, 14));
      layer.fields.push({
        name: 'Sender hardware address',
        attr: 'sha',
        data: parentLayer.payload.slice(8, 14)
      });
      layer.attrs.sha = sha;

      assertLength(18);
      let spa = new IPv4Address(parentLayer.payload.slice(14, 18));
      layer.fields.push({
        name: 'Sender protocol address',
        attr: 'spa',
        data: parentLayer.payload.slice(14, 18)
      });
      layer.attrs.spa = spa;

      assertLength(24);
      let tha = new MACAddress(parentLayer.payload.slice(18, 24));
      layer.fields.push({
        name: 'Target hardware address',
        attr: 'tha',
        data: parentLayer.payload.slice(18, 24)
      });
      layer.attrs.tha = tha;

      assertLength(28);
      let tpa = new IPv4Address(parentLayer.payload.slice(24, 28));
      layer.fields.push({
        name: 'Target protocol address',
        attr: 'spa',
        range: parentLayer.payload.slice(24, 28)
      });
      layer.attrs.tpa = tpa;

      let ethPadding = parentLayer.payload.slice(28);
      parentLayer.payload = parentLayer.payload.slice(0, 28);
      parentLayer.fields.push({
        name: 'Padding',
        attr: 'padding',
        data: ethPadding
      });
      parentLayer.attrs.padding = ethPadding;

      layer.summary = `[${operation.name.toUpperCase()}] ${sha}-${spa} -> ${tha}-${tpa}`;

    } catch (err) {
      layer.error = err.message;
    }

    parentLayer.layers[layer.namespace] = layer;
    return true;
  }
}
