import {
  Session
} from 'dripcap';

export default class TCP {
  activate() {
    Session.registerClass('dripcap/tcp/flags', `${__dirname}/flags.es`);
    Session.registerDissector([
      '::Ethernet::IPv4::<TCP>',
      '::Ethernet::IPv6::<TCP>'
    ], `${__dirname}/tcp.es`);
    Session.registerStreamDissector([
      '::Ethernet::IPv4::<TCP>',
      '::Ethernet::IPv6::<TCP>'
    ], `${__dirname}/tcp_stream.es`);
  }

  deactivate() {
    Session.unregisterClass(`${__dirname}/flags.es`);
    Session.unregisterDissector(`${__dirname}/tcp.es`);
    Session.unregisterStreamDissector(`${__dirname}/tcp_stream.es`);
  }
}
