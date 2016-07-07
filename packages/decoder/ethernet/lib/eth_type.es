import Enum from 'dripcap/enum';

export default class EthTypeEnum extends Enum {
  constructor(value) {
    let table = {
        0x0800 : 'IPv4',
        0x0806 : 'ARP',
        0x0842 : 'WoL',
        0x809B : 'AppleTalk',
        0x80F3 : 'AARP',
        0x86DD : 'IPv6'
    };
    super(table, value);
  }
}
