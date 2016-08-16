import {
  Session
} from 'dripcap';

export default class Ethernet {
  activate() {
    Session.registerClass('dripcap/eth/type', `${__dirname}/eth_type.es`);
    Session.registerDissector(['::<Ethernet>'], `${__dirname}/eth.es`);
  }

  deactivate() {
    Session.unregisterClass(`${__dirname}/eth_type.es`);
    Session.unregisterDissector(`${__dirname}/eth.es`);
  }
}
