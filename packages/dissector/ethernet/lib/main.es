export default class Ethernet {
  activate() {
    dripcap.session.registerClass('dripcap/eth/type', `${__dirname}/eth_type.es`);
    dripcap.session.registerDissector(['::<Ethernet>'], `${__dirname}/eth.es`);
  }

  deactivate() {
    dripcap.session.unregisterClass(`${__dirname}/eth_type.es`);
    dripcap.session.unregisterDissector(`${__dirname}/eth.es`);
  }
}
