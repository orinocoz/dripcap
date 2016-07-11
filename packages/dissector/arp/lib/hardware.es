import Enum from 'dripcap/enum';

export default class HardwareEnum extends Enum {
  constructor(value) {
    let table = {
      0x1: 'Ethernet'
    };
    super(table, value);
  }

  toMsgpack()
  {
    return [ this.value ];
  }
}
