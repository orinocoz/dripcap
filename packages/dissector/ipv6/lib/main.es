export default class IPv6 {
  activate()
  {
    dripcap.session.registerClass('dripcap/ipv6/protocol', `${__dirname}/protocol.es`);
    dripcap.session.registerDissector(['::Ethernet::<IPv6>'], `${__dirname}/ipv6.es`);
  }

  deactivate()
  {

  }
}
