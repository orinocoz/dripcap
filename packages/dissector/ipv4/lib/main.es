import {
  Session
} from 'dripcap';

export default class IPv4 {
  activate() {
    Session.registerClass('dripcap/ipv4/protocol', `${__dirname}/protocol.es`);
    Session.registerClass('dripcap/ipv4/fields', `${__dirname}/fields.es`);
    Session.registerDissector(['::Ethernet::<IPv4>'], `${__dirname}/ipv4.es`);
  }

  deactivate() {
    Session.unregisterClass(`${__dirname}/protocol.es`);
    Session.unregisterClass(`${__dirname}/fields.es`);
    Session.unregisterDissector(`${__dirname}/ipv4.es`);
  }
}
