export default class UDP {
  activate() {
    dripcap.session.on('created', (session) => {
      session.addDecoder(`${__dirname}/udp`)
    })
  }

  deactivate() {}
}
