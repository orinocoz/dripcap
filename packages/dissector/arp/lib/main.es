import {
  Session
} from 'dripcap';

export default class ARP {
  activate() {
    Session.registerClass('dripcap/arp/protocol', `${__dirname}/protocol.es`);
    Session.registerClass('dripcap/arp/hardware', `${__dirname}/hardware.es`);
    Session.registerClass('dripcap/arp/operation', `${__dirname}/operation.es`);
    Session.registerDissector(['::Ethernet::<ARP>'], `${__dirname}/arp.es`);
  }

  deactivate() {
    Session.unregisterClass(`${__dirname}/protocol.es`);
    Session.unregisterClass(`${__dirname}/hardware.es`);
    Session.unregisterClass(`${__dirname}/operation.es`);
    Session.unregisterDissector(`${__dirname}/arp.es`);
  }
}
