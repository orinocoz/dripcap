import {
  PacketStream
} from 'dripcap';

export default class TCPStreamDissector {
  constructor(options, context) {
    if (context.seq == null) {
      context.seq = -1;
      context.length = 0;
    }
    this.ctx = context;
  }

  analyze(packet, layer, data, output) {
    if (layer.payload.length > 0) {
      let stream = new PacketStream('TCP Stream', layer.namespace, layer.attrs.src + '/' + layer.attrs.dst);

      if (this.ctx.seq < 0) {
        this.ctx.length += layer.payload.length;
        stream.data = layer.payload;
      } else {
        let start = this.ctx.seq + this.ctx.length;
        let length = layer.payload.length;
        if (start > layer.attrs.seq) {
          length -= (start - layer.attrs.seq);
        }
        this.ctx.length += length;
        stream.data = layer.payload;
      }
      this.ctx.seq = layer.attrs.seq;
      output.push(stream);
    }
  }
}
