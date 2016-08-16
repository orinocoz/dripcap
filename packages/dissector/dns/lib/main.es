import {
  Session
} from 'dripcap';

export default class ARP {
  activate() {
    Session.registerClass('dripcap/dns/record', `${__dirname}/record.es`);
    Session.registerClass('dripcap/dns/operation', `${__dirname}/operation.es`);
    Session.registerDissector(['::Ethernet::IPv4::UDP', '::Ethernet::IPv6::UDP'], `${__dirname}/dns.es`);
  }

  deactivate() {
    Session.unregisterClass(`${__dirname}/record.es`);
    Session.unregisterClass(`${__dirname}/operation.es`);
    Session.unregisterDissector(`${__dirname}/dns.es`);
  }
}
