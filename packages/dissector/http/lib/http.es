import {
  Layer,
  Buffer
} from 'dripcap';

export default class HTTPDissector {
  constructor(options) {}

  analyze(packet, parentLayer) {
    parentLayer.payload = packet.payload;

    let method = parentLayer.attrs.method;
    parentLayer.fields.push({
      name: 'Method',
      attr: 'method',
      data: parentLayer.payload.slice(0, method.length)
    });

    let path = parentLayer.attrs.path;
    parentLayer.fields.push({
      name: 'Path',
      attr: 'path',
      data: parentLayer.payload.slice(method.length + 1, method.length + 1 + path.length)
    });

    let version = parentLayer.attrs.version;
    parentLayer.fields.push({
      name: 'Version',
      attr: 'version',
      data: parentLayer.payload.slice(method.length + 1 + path.length + 1, method.length + 1 + path.length + 1 + version.length)
    });

    parentLayer.fields.push({
      name: 'Payload',
      value: parentLayer.payload,
      data: parentLayer.payload
    });
  }
}
