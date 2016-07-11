export default class ARP {
  activate()
  {
    dripcap.session.registerClass('dripcap/dns/record', `${__dirname}/record.es`);
    dripcap.session.registerClass('dripcap/dns/operation', `${__dirname}/operation.es`);
    dripcap.session.registerDissector(['::Ethernet::IPv4::UDP', '::Ethernet::IPv6::UDP'], `${__dirname}/dns.es`);
  }

  deactivate()
  {

  }
}
