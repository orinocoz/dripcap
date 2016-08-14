export default class UDP {
  activate() {
    dripcap.session.registerDissector(['::Ethernet::IPv4::<UDP>', '::Ethernet::IPv6::<UDP>'], `${__dirname}/udp.es`);
  }

  deactivate() {
    dripcap.session.unregisterDissector(`${__dirname}/udp.es`);
  }
}
