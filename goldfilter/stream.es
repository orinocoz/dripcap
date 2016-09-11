import EventEmitter from 'events';

export default class BufferStream extends EventEmitter {
  constructor(id, gf) {
    super();
    this.id = id;
    this.index = 0;
    this.offset = 0;
    this.gf = gf;
  }

  async read(size) {
    if (Number.isInteger(size) && size <= 0) return null;
    let buffer = null;
    while (true) {
      let chunk = await this.gf.readStream(this.id, this.index++);
      if (chunk == null) break;
      if (this.offset > 0) {
        chunk = chunk.slice(this.offset);
        this.offset = 0;
      }
      buffer = Buffer.concat([buffer ? buffer : Buffer.from([]), chunk]);
      if (Number.isInteger(size) && buffer.length > size) {
        this.offset = chunk.length - (buffer.length - size);
        this.index--;
        buffer = buffer.slice(0, size);
        break;
      }
    }
    return buffer;
  }

  async length() {
    return this.gf.streamLength(this.id);
  }

  toString() {
    return `BufferStream <${this.id}>`;
  }

  static isStream(obj) {
    return (typeof obj === 'object' && obj.constructor.name === 'BufferStream');
  }
};
