export default class IPv4Host
{
  constructor(addr, port)
  {
    if (typeof addr !== 'object' || addr.constructor.name !== 'IPv4Address') {
      throw new TypeError('expected IPv4Address');
    }
    if (!Number.isInteger(port) || port < 0 || port > 65535) {
      throw new TypeError('invalid port');
    }
    this.addr = addr;
    this.port = port;
  }

  toString()
  {
    return `${this.addr}:${this.port}`
  }

  toJSON()
  {
    return this.toString();
  }

  toMsgpack()
  {
    return [ this.addr, this.port ];
  }

  equals(value)
  {
    return val.toString() === this.toString();
  }
}
