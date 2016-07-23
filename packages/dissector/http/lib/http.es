import {NetStream, Packet, Layer} from 'dripcap';

export default class TCPStreamDissector
{
  constructor(options)
  {

  }

  analyze(packet, parentLayer, data, output)
  {
    let body = data.toString('utf8');
    let re = /(GET|POST) (\S+) HTTP\/(0\.9|1\.0|1\.1)\r\n/;
    let m = body.match(re);
    if (m != null) {
      let pkt = new Packet;

      let layer = new Layer();
      layer.name = 'HTTP';
      layer.namespace = layer.namespace + '::HTTP';
      layer.attrs.src = parentLayer.attrs.src;
      layer.attrs.dst = parentLayer.attrs.dst;

      layer.fields.push({
        name: 'Method',
        value: m[1]
      });
      layer.attrs.mathod = m[1];

      pkt.layers[layer.namespace] = layer;
      output.push(pkt);
    }
  }
}
