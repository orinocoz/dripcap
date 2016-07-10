import {Buffer} from 'dripcap';

export default class IPv6Address
{
  constructor(data)
  {
    if (!Buffer.isBuffer(data)) {
      throw new TypeError('expected Buffer');
    }
    if (data.length !== 16) {
      throw new TypeError('invalid address length');
    }
    this.data = data;
  }

  toString()
  {
    let hex = this.data.toString('hex');
    let str = '';
    for (let i = 0; i < 8; ++i) {
      str += hex.substr(i * 4, 4).replace(/0{0,3}/, '');
      str += ':';
    }
    str = str.substr(0, str.length - 1);
    seq = str.match(/:0:(?:0:)+/g);
    if (seq != null) {
      seq.sort((a, b) => {b.length - a.length});
      str = str.replace(seq[0], '::');
    }
    return str;
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
