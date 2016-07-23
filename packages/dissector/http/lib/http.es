import {NetStream} from 'dripcap';

export default class TCPStreamDissector
{
  constructor(options)
  {

  }

  analyze(packet, layer, data, output)
  {
    if (data.toString('hex').startsWith('4745')) {
      console.error(layer.attrs.dst, layer.payload.toString('utf8'))
    }
  }
}
