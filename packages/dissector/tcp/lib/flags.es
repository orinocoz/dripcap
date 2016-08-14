import Flags from 'dripcap/flags';

export default class TCPFlags extends Flags {
  constructor(value) {
    let table = {
      'NS': 0x1 << 8,
      'CWR': 0x1 << 7,
      'ECE': 0x1 << 6,
      'URG': 0x1 << 5,
      'ACK': 0x1 << 4,
      'PSH': 0x1 << 3,
      'RST': 0x1 << 2,
      'SYN': 0x1 << 1,
      'FIN': 0x1 << 0,
    };
    super(table, value);
  }

  toMsgpack() {
    return [this.value];
  }
}
