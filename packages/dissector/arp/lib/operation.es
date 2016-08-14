import Enum from 'dripcap/enum';

export default class OperationEnum extends Enum {
  constructor(value) {
    let table = {
      0x1: 'request',
      0x2: 'reply'
    };
    super(table, value);
  }

  toMsgpack() {
    return [this.value];
  }
}
