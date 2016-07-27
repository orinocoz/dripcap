const chai = require('chai');
chai.should();
chai.use(require('chai-also'));
chai.use(require('chai-as-promised'));
const path = require('path');

require("babel-register")({
    presets : [ "es2015" ],
    extensions : [ ".es" ]
});

const GoldFilter = require('../index.es').default;

describe('GoldFilter', function() {
    this.timeout(10000);

    describe('#requestPackets()', () => {
        it('should emit packet', () => {
            const gf = new GoldFilter();
            return gf.setTestData(path.join(__dirname, '/test.msgpack'))
                .then(() => {
                          return gf.addClass('dripcap/mac', path.join(__dirname, '/mac.es'))})
                .then(() => {
                    return gf.addDissector([ '::<Ethernet>' ], path.join(__dirname, '/eth.es'));
                })
                .then(() => {
                    return gf.addDissector([ '::Ethernet::<IPv4>' ], path.join(__dirname, '/ipv4.es'));
                })
                .then(() => {
                    gf.start('en0');
                })
                .then(() => {
                    return new Promise((res) => {
                        gf.on('status', (stat) => {
                            if (stat.packets > 100) {
                                res(stat);
                            }
                        });
                    });
                })
                .then(() => {
                    return new Promise((res) => {
                        gf.on('packet', (pkt) => {
                            res(pkt);
                            console.log(JSON.stringify(pkt))
                        });
                        gf.requestPackets([ 100 ]);
                    });
                })
                .should.eventually.have.property('id', 100)
                .and.also.have.property('ts_sec', 1467382481)
                .and.also.have.property('ts_nsec', 237003)
                .and.also.have.property('len', 100)
                .and.also.have.deep.property('payload.length', 100)
                .and.also.have.deep.property('layers.::<Ethernet>.payload.length')
                .and.also.have.deep.property('layers.::<Ethernet>.layers.::Ethernet::<IPv4>.layers.::Ethernet::IPv4');

            after(() => {
                gf.stop();
            });
        });
    });
});
