import {
  Session
} from 'dripcap';

export default class TCP {
  activate() {
    Session.registerDissector([
      '::Ethernet::IPv4::TCP::<HTTP>',
      '::Ethernet::IPv6::TCP::<HTTP>'
    ], `${__dirname}/http.es`);
    Session.registerStreamDissector([
      '::Ethernet::IPv4::TCP',
      '::Ethernet::IPv6::TCP'
    ], `${__dirname}/http_stream.es`);
  }

  deactivate() {
    Session.unregisterStreamDissector(`${__dirname}/http_stream.es`);
    Session.unregisterDissector(`${__dirname}/http.es`);
  }
}
