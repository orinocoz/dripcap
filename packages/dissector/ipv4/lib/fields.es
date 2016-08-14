import Flags from 'dripcap/flags';

export default class FieldFlags extends Flags {
  constructor(value) {
    let table = {
      'Reserved': 0x1,
      'Don\'t Fragment': 0x2,
      'More Fragments': 0x4,
    };
    super(table, value);
  }

  toMsgpack() {
    return [this.value];
  }
}
