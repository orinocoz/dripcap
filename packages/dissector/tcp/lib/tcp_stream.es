export default class TCPStreamDissector
{
  constructor(options)
  {
    this.count = 0;
  }

  analyze(packet, layer, data, output)
  {
    this.count++;
    console.error(packet.id, layer.name, data.length, this.count)
  }
}
