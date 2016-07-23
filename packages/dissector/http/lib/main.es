export default class TCP {
  activate()
  {
    dripcap.session.registerStreamDissector([
      '::Ethernet::IPv4::TCP',
      '::Ethernet::IPv6::TCP'
    ], `${__dirname}/http.es`);
  }

  deactivate()
  {
      dripcap.session.unregisterStreamDissector(`${__dirname}/http.es`);
  }
}
