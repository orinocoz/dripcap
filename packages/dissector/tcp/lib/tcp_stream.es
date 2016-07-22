import {NetStream} from 'dripcap';

export default class TCPStreamDissector
{
  constructor(options)
  {
    this.seq = -1;
    this.length = 0;
  }

  analyze(packet, layer, data, output)
  {
    if (layer.payload.length > 0) {
      if (this.seq < 0) {
        this.length += layer.payload.length;
      } else {
        let start = this.seq + this.length;
        let length = layer.payload.length;
        if (start > layer.attrs.seq) {
          length -= (start - layer.attrs.seq);
        }
        this.length += length;
      }
      this.seq = layer.attrs.seq;
    }
    let stream = new NetStream('TCP Stream', layer.namespace, layer.attrs.src + '/' + layer.attrs.dst);
    output.push(stream);
    //console.error(layer.name, this.seq, this.length)
  }
}
