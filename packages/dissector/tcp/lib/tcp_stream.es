import {
  PacketStream
} from 'dripcap';

export default class TCPStreamDissector {
  constructor(options) {
    this.seq = -1;
    this.length = 0;
  }

  analyze(packet, layer, data, output) {
    if (layer.payload.length > 0) {
      let stream = new PacketStream('TCP Stream', layer.namespace, layer.attrs.src + '/' + layer.attrs.dst);

      if (this.seq < 0) {
        this.length += layer.payload.length;
        stream.data = layer.payload;
      } else {
        let start = this.seq + this.length;
        let length = layer.payload.length;
        if (start > layer.attrs.seq) {
          length -= (start - layer.attrs.seq);
        }
        this.length += length;
        stream.data = layer.payload;
      }
      this.seq = layer.attrs.seq;
      output.push(stream);
    }
  }
}
