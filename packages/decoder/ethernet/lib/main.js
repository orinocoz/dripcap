export default class Ethernet {
  activate() {
    dripcap.session.on('created', (session) => {
      session.addDecoder(`${__dirname}/ethernet`)
    })
  }

  deactivate() {}
}
