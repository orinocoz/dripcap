export default class ARP {
  activate()
  {
    dripcap.session.registerClass('dripcap/arp/protocol', `${__dirname}/protocol.es`);
    dripcap.session.registerClass('dripcap/arp/hardware', `${__dirname}/hardware.es`);
    dripcap.session.registerClass('dripcap/arp/operation', `${__dirname}/operation.es`);
    dripcap.session.registerDissector(['::Ethernet::<ARP>'], `${__dirname}/arp.es`);
  }

  deactivate()
  {

  }
}
