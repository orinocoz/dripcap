import Enum from 'dripcap/enum';

export default class ProtocolEnum extends Enum {
  constructor(value) {
    let table = {
      0x0800: 'IPv4',
      0x86DD: 'IPv6',
    };
    super(table, value);
  }

  toMsgpack() {
    return [this.value];
  }
}
