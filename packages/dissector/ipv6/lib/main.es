import {
  Session
} from 'dripcap';

export default class IPv6 {
  activate() {
    Session.registerClass('dripcap/ipv6/protocol', `${__dirname}/protocol.es`);
    Session.registerDissector(['::Ethernet::<IPv6>'], `${__dirname}/ipv6.es`);
  }

  deactivate() {
    Session.unregisterClass(`${__dirname}/protocol.es`);
    Session.unregisterDissector(`${__dirname}/ipv6.es`);
  }
}
