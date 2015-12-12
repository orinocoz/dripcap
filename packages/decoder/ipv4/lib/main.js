export default class IPv4 {
  activate() {
    dripcap.session.on('created', (session) => {
      session.addDecoder("#{__dirname}/ipv4")
    })
  }

  deactivate() {}
}
