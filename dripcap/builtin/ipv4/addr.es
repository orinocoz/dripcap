import {
  Buffer
} from 'dripcap';

export default class IPv4Address {
  constructor(data) {
    if (typeof data == 'string') {
      data = new Buffer(data.split('.').map((v) => {
        parseInt(v)
      }));
    }
    if (!Buffer.isBuffer(data)) {
      throw new TypeError('expected Buffer');
    }
    if (data.length !== 4) {
      throw new TypeError('invalid address length');
    }
    this.data = data;
  }

  toString() {
    return `${this.data[0]}.${this.data[1]}.${this.data[2]}.${this.data[3]}`;
  }

  toJSON() {
    return this.toString();
  }

  toMsgpack() {
    return [this.data];
  }

  equals(value) {
    return this.data.equals(value.data);
  }
}
