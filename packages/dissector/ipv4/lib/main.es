export default class IPv4 {
  activate()
  {
    dripcap.session.registerClass('dripcap/ipv4/protocol', `${__dirname}/protocol.es`);
    dripcap.session.registerClass('dripcap/ipv4/fields', `${__dirname}/fields.es`);
    dripcap.session.registerDissector(['::Ethernet::<IPv4>'], `${__dirname}/ipv4.es`);
  }

  deactivate()
  {
    dripcap.session.unregisterClass(`${__dirname}/protocol.es`);
    dripcap.session.unregisterClass(`${__dirname}/fields.es`);
    dripcap.session.unregisterDissector(`${__dirname}/ipv4.es`);
  }
}
