import {
  Session
} from 'dripcap';

export default class UDP {
  activate() {
    Session.registerDissector(['::Ethernet::IPv4::<UDP>', '::Ethernet::IPv6::<UDP>'], `${__dirname}/udp.es`);
  }

  deactivate() {
    Session.unregisterDissector(`${__dirname}/udp.es`);
  }
}
