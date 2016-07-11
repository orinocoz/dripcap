import {Layer, Buffer} from 'dripcap';
import MACAddress from 'dripcap/mac';
import RecordEnum from 'dripcap/dns/record';
import OperationEnum from 'dripcap/dns/operation';

export default class DNSDissector
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
    layer.name = 'DNS';
    layer.namespace = parentLayer.namespace + '::DNS';

    try {

      assertLength(12);
      let id = parentLayer.payload.readUInt16BE(0, true);
      let flags0 = parentLayer.payload.readUInt8(2, true);
      let flags1 = parentLayer.payload.readUInt8(3, true);
      let qr = !!(flags0 >> 7);

      let opcode = new OperationEnum((flags0 >> 3) & 0b00001111);
      if (!opcode.known) {
        throw new Error('wrong DNS opcode');
      }

      let aa = !!((flags0 >> 2) & 1);
      let tc = !!((flags0 >> 1) & 1);
      let rd = !!((flags0 >> 0) & 1);
      let ra = !!(flags1 >> 7);

      if (flags1 & 0b01110000) {
        throw new Error('reserved bits must be zero');
      }

      let rcode = new RecordEnum(flags1 & 0b00001111);
      if (!rcode.known) {
        throw new Error('wrong DNS rcode');
      }

      let qdCount = parentLayer.payload.readUInt16BE(4, true);
      let anCount = parentLayer.payload.readUInt16BE(6, true);
      let nsCount = parentLayer.payload.readUInt16BE(8, true);
      let arCount = parentLayer.payload.readUInt16BE(10, true);

      layer.fields.push({
        name: 'ID',
        attr: 'id',
        data: parentLayer.payload.slice(0, 2)
      });
      layer.attrs.id = id;

      layer.fields.push({
        name: 'Query/Response Flag',
        attr: 'qr',
        data: parentLayer.payload.slice(2, 3)
      });
      layer.attrs.qr = qr;

      layer.fields.push({
        name: 'Operation Code',
        attr: 'opcode',
        data: parentLayer.payload.slice(2, 3)
      });
      layer.attrs.opcode = opcode;

      layer.fields.push({
        name: 'Authoritative Answer Flag',
        attr: 'aa',
        data: parentLayer.payload.slice(2, 3)
      });
      layer.attrs.aa = aa;

      layer.fields.push({
        name: 'Truncation Flag',
        attr: 'tc',
        data: parentLayer.payload.slice(2, 3)
      });
      layer.attrs.tc = tc;

      layer.fields.push({
        name: 'Recursion Desired',
        attr: 'rd',
        data: parentLayer.payload.slice(2, 3)
      });
      layer.attrs.rd = rd;

      layer.fields.push({
        name: 'Recursion Available',
        attr: 'ra',
        data: parentLayer.payload.slice(3, 4)
      });
      layer.attrs.ra = ra;

      layer.fields.push({
        name: 'Response Code',
        attr: 'rcode',
        data: parentLayer.payload.slice(3, 4)
      });
      layer.attrs.rcode = rcode;

      layer.fields.push({
        name: 'Question Count',
        attr: 'qdCount',
        data: parentLayer.payload.slice(4, 6)
      });
      layer.attrs.qdCount = qdCount;

      layer.fields.push({
        name: 'Answer Record Count',
        attr: 'anCount',
        data: parentLayer.payload.slice(6, 8)
      });
      layer.attrs.anCount = anCount;

      layer.fields.push({
        name: 'Authority Record Count',
        attr: 'nsCount',
        data: parentLayer.payload.slice(8, 10)
      });
      layer.attrs.nsCount = nsCount;

      layer.fields.push({
        name: 'Additional Record Count',
        attr: 'arCount',
        data: parentLayer.payload.slice(10, 12)
      });
      layer.attrs.arCount = arCount;

      layer.payload = parentLayer.payload.slice(12);
      layer.fields.push({
        name: 'Payload',
        value: layer.payload,
        data: layer.payload
      });

      layer.summary = `[${opcode.name}] [${rcode.name}] qd:${qdCount} an:${anCount} ns:${nsCount} ar:${arCount}`;

    } catch (err) {
      layer.error = err.message;
    }

    parentLayer.layers[layer.namespace] = layer;
    return true;
  }
}
