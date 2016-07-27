export default class TCP {
  activate()
  {
    dripcap.session.registerDissector([
      '::Ethernet::IPv4::TCP::<HTTP>',
      '::Ethernet::IPv6::TCP::<HTTP>'
    ], `${__dirname}/http.es`);
    dripcap.session.registerStreamDissector([
      '::Ethernet::IPv4::TCP',
      '::Ethernet::IPv6::TCP'
    ], `${__dirname}/http_stream.es`);
  }

  deactivate()
  {
      dripcap.session.unregisterStreamDissector(`${__dirname}/http_stream.es`);
      dripcap.session.unregisterDissector(`${__dirname}/http.es`);
  }
}
