import Enum from 'dripcap/enum';

export default class RecordEnum extends Enum {
  constructor(value) {
    let table = {
      0: 'No Error',
      1: 'Format Error',
      2: 'Server Failure',
      3: 'Name Error',
      4: 'Not Implemented',
      5: 'Refused',
      6: 'YX Domain',
      7: 'YX RR Set',
      8: 'NX RR Set',
      9: 'Not Auth',
      10: 'Not Zone',
    };
    super(table, value);
  }

  toMsgpack() {
    return [this.value];
  }
}
