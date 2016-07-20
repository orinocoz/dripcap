export default class TCP {
  activate()
  {
    dripcap.session.registerClass('dripcap/tcp/flags', `${__dirname}/flags.es`);
    dripcap.session.registerDissector([
      '::Ethernet::IPv4::<TCP>',
      '::Ethernet::IPv6::<TCP>'
    ], `${__dirname}/tcp.es`);
    dripcap.session.registerStreamDissector([
      '::Ethernet::IPv4::<TCP>',
      '::Ethernet::IPv6::<TCP>'
    ], `${__dirname}/tcp_stream.es`);
  }

  deactivate()
  {
      dripcap.session.unregisterClass(`${__dirname}/flags.es`);
      dripcap.session.unregisterDissector(`${__dirname}/tcp.es`);
      dripcap.session.unregisterStreamDissector(`${__dirname}/tcp_stream.es`);
  }
}
