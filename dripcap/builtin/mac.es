import {Buffer} from 'dripcap';

export default class MACAddress
{
  constructor(data)
  {
    if (typeof data == 'string') {
      data = new Buffer(data.replace(/[:-]/g, ''), 'hex');
    }
    if (!Buffer.isBuffer(data)) {
      throw new Error('expected Buffer or String');
    }
    if (data.length !== 6) {
      throw new Error('invalid address length');
    }
    this.data = data;
  }

  toString()
  {
    return this.data.toString('hex').replace(/..(?=.)/g, '$&:');
  }

  toJSON()
  {
    return this.toString();
  }

  toMsgpack()
  {
    return [ this.data ];
  }

  equals(value)
  {
    return this.data.equals(value.data);
  }
}
