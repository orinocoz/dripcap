require('babel-core/register')({ignore: /.+\/node_modules\/(?!dripper).+\/.+.js/})
import 'coffee-script/register'
import 'dripper/type'
import _ from 'underscore'
import net from 'net'
import msgpack from 'msgcap'
import PaperFilter from 'paperfilter'

class DecoderMap {
  constructor() {
    this._map = {}
  }

  addDecoder(decoder) {
    for (let p of decoder.lowerLayers) {
      if (this._map[p] == null) {
        this._map[p] = []
      }
      this._map[p].push(decoder)
    }
  }

  analyze(packet) {
    return Promise.resolve().then((function(_this) {
      return function() {
        var array, decoder, i, len, prom;
        prom = Promise.resolve(packet);
        if (array = _this._map[_.last(packet.layers).namespace]) {
          for (i = 0, len = array.length; i < len; i++) {
            decoder = array[i];
            prom = (function(decoder) {
              return prom.then(function() {
                return new Promise(function(res, rej) {
                  return process.nextTick(function() {
                    return decoder.analyze(packet).then(rej, res);
                  });
                });
              });
            })(decoder);
          }
        }
        prom = prom.then(function() {
          return Promise.resolve(packet);
        });
        return prom.then(function(packet) {
          return Promise.resolve(packet);
        }, function(packet) {
          return _this.analyze(packet);
        });
      };
    })(this));
  }
}

class Session {
  constructor(filterPath) {
    this.filterPath = filterPath
    this._captures = []
    this._filters = []
    this._decoderMap = new DecoderMap()
  }

  load(decoder) {
    let klass = require(decoder)
    this._decoderMap.addDecoder(new klass())
  }

  connect(sock) {
    if (this._conn != null) {
      this._conn.end()
    }
    this._conn = net.createConnection(sock)
  }

  capture(option) {
    this._captures.push(option)
  }

  start() {
    this.stop()
    for (let c of this._captures) {
      let f = new PaperFilter()
      f.on('packet', (packet) => {
        this._decoderMap.analyze(packet).then((packet) => {
          this._conn.write(msgpack.encode(packet))
        })
      })
      f.start(c.iface, c.options)
      this._filters.push(f)
    }
  }

  stop() {
    for (let f of this._filters) {
      f.stop()
      f.removeAllListeners()
    }
    this._filters = []
  }
}

global.session = new Session()
