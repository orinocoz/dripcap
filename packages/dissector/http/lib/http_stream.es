import {
  NetStream,
  StreamLayer
} from 'dripcap';

export default class TCPStreamDissector {
  constructor(options) {

  }

  analyze(packet, parentLayer, data, output) {
    let body = data.toString('utf8');
    let re = /(GET|POST) (\S+) (HTTP\/(0\.9|1\.0|1\.1))\r\n/;
    let m = body.match(re);
    if (m != null) {

      let name = 'HTTP';
      let namespace = parentLayer.namespace + '::<HTTP>';
      let attrs = {
        method: m[1],
        path: m[2],
        version: m[3],
        src: parentLayer.attrs.src,
        dst: parentLayer.attrs.dst
      };
      let payload = data;

      let layer = new StreamLayer(name, namespace, attrs, payload);
      output.push(layer);
    }
  }
}
