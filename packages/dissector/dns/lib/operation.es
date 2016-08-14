import Enum from 'dripcap/enum';

export default class OperationEnum extends Enum {
  constructor(value) {
    let table = {
      0: 'QUERY',
      1: 'IQUERY',
      2: 'STATUS',
      4: 'NOTIFY',
      5: 'UPDATE',
    };
    super(table, value);
  }

  toMsgpack() {
    return [this.value];
  }
}
