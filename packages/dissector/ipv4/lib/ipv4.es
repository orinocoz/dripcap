import {Layer, Buffer} from 'dripcap';
import MACAddress from 'dripcap/mac';
import ProtocolEnum from 'dripcap/ipv4/protocol';
import IPv4Address from 'dripcap/ipv4/addr';

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

    layer.payload = parentLayer.payload.slice(14);

    layer.fields.push({
      name : 'Payload',
      value : layer.payload,
      data : layer.payload
    });

    layer.summary = "ipv4";

    parentLayer.layers[layer.namespace] = layer;
    return true;
  }
}
