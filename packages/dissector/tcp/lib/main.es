export default class TCP {
  activate()
  {
    dripcap.session.registerClass('dripcap/tcp/flags', `${__dirname}/flags.es`);
    dripcap.session.registerDissector(['::Ethernet::IPv4::<TCP>', '::Ethernet::IPv6::<TCP>'], `${__dirname}/tcp.es`);
  }

  deactivate()
  {

  }
}
