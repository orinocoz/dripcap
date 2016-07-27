function underscore(str) {
  return str.replace(/[\s-]+/, '_')
  .replace(/([a-z])([A-Z])/, (m, s1, s2) => {
    return s1 + '_' + s2.toLowerCase();
  })
  .toLowerCase();
}

export default class Flags
{
  constructor(table, value)
  {
    if (typeof table !== 'object') {
      throw new TypeError('expected Object');
    }
    if (!Number.isInteger(value)) {
      throw new TypeError('expects Integer');
    }
    this.table = table;
    this.value = value;

    this.attrs = {}
    for (let k in this.table) {
      this.attrs[underscore(k)] = this.get(k);
    }
  }

  get(key)
  {
    if (this.table[key] != null) {
      return !!(this.value & this.table[key]);
    } else {
      return false;
    }
  }

  is(key)
  {
    return this.value === this.table[key];
  }

  toString()
  {
    let values = [];
    for (let k in this.table) {
      if (this.get(k)) {
        values.push(k);
      }
    }

    if (values.length > 0) {
      return `${values.join(', ')} (${this.value})`;
    } else {
      return `none (${this.value})`;
    }
  }

  toJSON()
  {
    return this.toString();
  }

  toMsgpack()
  {
    let table = {};
    if (this.known) {
      table[this.value] = this.table[this.value];
    }
    return [ table, this.value ];
  }

  equals(val)
  {
    return val.toString() === this.toString();
  }
}
