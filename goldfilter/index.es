import path from 'path';
import net from 'net';
import fs from 'fs';
import os from 'os';
import crypto from 'crypto';
import childProcess from 'child_process';
import EventEmitter from 'events';
import msgpack from 'msgpack-lite';
import uuid from 'node-uuid';
import tmp from 'tmp';
import {
  rollup
} from 'rollup';
import esprima from 'esprima';
import LRU from 'lru-cache';

var exeEnv = {
  env: {
    'GOLDFILTER_LOG': 'error'
  }
};

class Payload extends Buffer {

};

class Layer {
  constructor(namespace, params) {
    this.namespace = namespace;
    this.name = params.name || this.namespace;
    this.aliases = params.aliases || [];
    this.payloadOffset = params.payloadOffset || 0;
    this.fields = params.fields || [];
    this.attrs = params.attrs || {};
    this.data = params.data || {};

    if (params.summary != null) {
      this.summary = params.summary;
    }
    if (params.error != null) {
      this.error = params.error;
    }
    if (params.payload != null) {
      this.payload = params.payload;
    }

    function makeAttrs(fields) {
      for (let f of fields) {
        if (f.attr != null) {
          this.attrs[f.attr] = f.value;
        }
        if (f.fields != null) {
          makeAttrs(f.fields);
        }
      }
    }
  }
}

function leafLayer(layer) {
  if (layer.layers != null) {
    let ns = Object.keys(layer.layers);
    if (ns.length > 0) {
      return leafLayer(layer.layers[ns[0]]);
    }
  }
  return layer;
}

class Packet {
  constructor(data) {
    for (let k in data) {
      this[k] = data[k];
    }
  }

  get namespace() {
    if (Object.keys(this.layers).length === 0) {
      throw new Error('empty packet');
    }
    let layer = leafLayer(this.layers[Object.keys(this.layers)[0]]);
    return layer.namespace || '';
  }

  get name() {
    if (Object.keys(this.layers).length === 0) {
      throw new Error('empty packet');
    }
    let layer = leafLayer(this.layers[Object.keys(this.layers)[0]]);
    return layer.name || '';
  }

  get attrs() {
    if (Object.keys(this.layers).length === 0) {
      throw new Error('empty packet');
    }
    let attrs = {};

    function getAttrs(layers) {
      for (let ns in layers) {
        let layer = layers[ns];
        if (layer.attrs != null) {
          for (let k in layer.attrs) {
            attrs[k] = layer.attrs[k]
          }
        }
        if (layer.layers != null) {
          getAttrs(layer.layers);
        }
      }
    }
    getAttrs(this.layers);
    return attrs;
  }

  get timestamp() {
    return new Date(this.ts_sec * 1000);
  }
}

export default class GoldFilter extends EventEmitter {
  constructor() {
    super();

    const prefix = (process.platform === 'win32') ? '\\\\?\\pipe' : os.tmpdir();
    this.sockPath = path.join(prefix, uuid.v4() + '.sock');
    this.sock = new net.Socket();

    let tmpobj = tmp.dirSync({unsafeCleanup: true, prefix: 'dripcap-'});
    this.tmpDir = tmpobj.name;

    process.on('exit', () => {
      fs.unlinkSync(this.sockPath);
    });

    const {
      bundle,
      exe
    } = GoldFilter._getPath();

    let exePath = exe;
    try {
      fs.accessSync(exePath);
    } catch (err) {
      exePath = bundle;
    }

    this.child = childProcess.execFile(exePath, [this.sockPath, this.tmpDir], exeEnv, (err) => {
      console.error(err);
    });
    this.child.stdout.pipe(process.stdout);

    this.callbacks = [];
    this.callid = 0;

    this.msgpackClasses = {};
    this.filterClasses = {};
    this.filterSource = fs.readFileSync(path.join(__dirname, './filter.es'));

    this.classPromise = Promise.resolve();

    this.packetCache = LRU(5000);

    this.connected = new Promise((res) => {
      this.sock.on('error', (err) => {
        if (err.code === 'ENOENT' || err.code === 'EACCES') {
          setTimeout(() => {
            this.sock.connect(this.sockPath);
          }, 100);
        }
      })

      this.sock.connect(this.sockPath);

      this.sock.on('connect', (err) => {
        let codec = msgpack.createCodec();
        codec.addExtUnpacker(0x1B, Buffer);
        this.sock.pipe(msgpack.createDecodeStream({
          codec: codec
        })).on("data", (data) => {
          const callid = data[0];
          const cb = this.callbacks[callid];
          if (cb)
            cb(data[1]);

          delete this.callbacks[callid];
        });

        this.pingTimer = setInterval(() => {
          this._call('ping');
        }, 10000);

        res();
      })
    })

    if (process.env['DRIPCAP_UI_TEST'] != null) {
      let testPath = process.env['DRIPCAP_UI_TEST'];
      let devices = msgpack.decode(fs.readFileSync(path.join(testPath, 'list.msgpack')));
      let packets = [];
      try {
        let count = 0;
        for (;; ++count) {
          let num = ('00' + count).slice(-3);
          let packetPath = path.join(testPath, `packet${num}.msgpack`);
          let packet = msgpack.decode(fs.readFileSync(packetPath));
          packets.push(packet);
        }
      } catch (e) {}
      this._call('set_testdata', {
        packets: packets,
        devices: devices
      });
    }
  }

  _call(name, arg) {
    return this.connected.then(() => {
      return new Promise((res) => {
        this.callbacks[++this.callid] = res;
        this.sock.write(msgpack.encode([name, this.callid, arg || {}]));
      });
    })
  }

  _build(jsPath) {
    return new Promise((res, rej) => {
      let hash = crypto.createHash('sha256');
      fs.createReadStream(jsPath).pipe(hash);

      hash.on('readable', () => {
        let data = hash.read();
        if (data != null) {
          let cachePath = path.join(this.tmpDir, data.toString('hex') + '.dripcap.es');
          fs.readFile(cachePath, 'utf8', (err, data) => {
            if (err == null) {
              res(data);
            } else {
              rollup({
                entry: jsPath,
                onwarn: () => {}
              }).then((bundle) => {
                const result = bundle.generate({
                  format: 'es'
                });
                const js = path.join(this.tmpDir, uuid.v4() + '.dripcap.es');
                return new Promise((res, rej) => {
                  fs.writeFile(js, result.code, (err) => {
                    if (err) throw err;
                    rollup({
                      entry: js,
                      onwarn: () => {}
                    }).then(res, rej);
                  });
                });
              }).then((bundle) => {
                const result = bundle.generate({
                  format: 'cjs'
                });
                fs.writeFile(cachePath, result.code, () => {
                  res(result.code);
                });
              }).catch((e) => {
                rej(e);
              });
            }
          });
        }
      });
    });
  }

  _getPackets(start, end) {
    if (Array.isArray(start)) {
      return this._call('get_packets', {
        list: start
      });
    } else {
      return this._call('get_packets', {
        range: [start, end]
      });
    }
  }

  devices() {
    return this._call('get_devices');
  }

  addDissector(namespaces, path) {
    return this._build(path).then((source) => {
      return this._call('load_dissector', {
        source: source,
        options: {
          namespaces: namespaces || []
        }
      })
    })
  }

  addStreamDissector(namespaces, path) {
    return this._build(path).then((source) => {
      return this._call('load_stream_dissector', {
        source: source,
        options: {
          namespaces: namespaces || []
        }
      })
    })
  }

  addClass(name, filePath) {
    let classPromise = this.classPromise;
    let prom = this._build(filePath).then((source) => {
      return classPromise.then(() => {
        return source;
      });
    }).then((source) => {
      let func = new Function('require', 'module', source);
      let mod = {};
      func((name) => {
        if (name === 'dripcap') {
          return {
            Buffer: Buffer
          };
        }
        if (this.msgpackClasses[name] != null) {
          return this.msgpackClasses[name];
        }
        return require(name);
      }, mod);
      this.msgpackClasses[name] = mod.exports;
      this.filterClasses[name] = source;
      return this._call('load_module', {
        name: name,
        source: source
      });
    });

    this.classPromise = prom;
    return prom;
  }

  start(ifs, options = {}) {
    return this._call('set_opt', Object.assign({}, {
      interface: ifs
    }, options)).then(() => {
      return this._call('start');
    });
  }

  status() {
    return this._call('get_status');
  }

  setFilter(name, filter = "") {
    let body = '';
    const ast = esprima.parse(filter);
    switch (ast.body.length) {
      case 0:
        break;
      case 1:
        const root = ast.body[0];
        if (root.type !== "ExpressionStatement")
          throw new SyntaxError();
        body = 'var ast = ' + JSON.stringify(root.expression) + ';\n' + this.filterSource;
        break;
      default:
        throw new SyntaxError();
    }

    return this._call('set_filter', {
      source: body,
      name: name,
      options: {}
    });
  }

  requestPackets(start, end) {
    let requests = [];
    if (Array.isArray(start)) {
      for (let id of start) {
        let pkt = this.packetCache.get(id);
        if (pkt == null) {
          requests.push(id);
        } else {
          this.emit('packet', pkt);
        }
      }
    } else {
      for (let id = start; id <= end; ++id) {
        let pkt = this.packetCache.get(id);
        if (pkt == null) {
          requests.push(id);
        } else {
          this.emit('packet', pkt);
        }
      }
    }
    if (requests.length === 0) {
      return Promise.resolve();
    }
    return this._getPackets(requests).then((packets) => {
      for (let pkt of packets) {
        let codec = msgpack.createCodec();
        codec.depends = [];
        codec.addExtUnpacker(0x1B, Buffer);
        codec.addExtUnpacker(0x20, (buffer) => {
          const args = msgpack.decode(buffer, {
            codec: codec
          });
          const cls = this.msgpackClasses[args[0]];
          if (cls != null) {
            return new(Function.prototype.bind.apply(cls, [null].concat(args.slice(1))));
          }
          return buffer;
        });
        codec.addExtUnpacker(0x1F, ((pkt) => {
          return (buffer) => {
            const tuple = msgpack.decode(buffer, {
              codec: codec
            });
            let slice = pkt.payload.slice(tuple[0], tuple[1]);
            slice.start = tuple[0];
            slice.end = tuple[1];
            return slice;
          };
        })(pkt))

        pkt.layers = msgpack.decode(pkt.layers.buffer, {
          codec: codec
        });
        let packet = new Packet(pkt);
        this.packetCache.set(pkt.id, packet);
        this.emit('packet', packet);
      }
      return Promise.resolve();
    });
  }

  getFiltered(name, start, end) {
    return this._call('get_filtered', {
      name: name,
      range: [start, end]
    });
  }

  logs() {
    return this._call('fetch_logs');
  }

  stop() {
    return this._call('stop');
  }

  close() {
    clearInterval(this.pingTimer);
    return this._call('exit');
  }

  static _getPath() {
    const helperPath = path.join(__dirname, '../../../../Frameworks/Dripcap Helper Installer.app');
    const helperPfPath = path.join(helperPath, '/Contents/Resources/goldfilter');
    const helperAppPath = path.join(helperPath, '/Contents/MacOS/Dripcap Helper Installer');

    let bundle = path.join(__dirname, '/build/goldfilter');

    if (process.platform == 'win32')
      bundle += '.exe';

    if (process.platform == 'darwin') {
      try {
        fs.accessSync(helperPfPath);
        bundle = helperPfPath;
      } catch (err) {
        // console.warn(err);
      }
    }

    let exe = '';
    if (process.env['DRIPCAP_UI_TEST'] != null || process.platform == 'win32') {
      exe = bundle;
    } else if (process.platform == 'darwin') {
      exe = '/usr/local/lib/goldfilter';
    } else {
      exe = '/usr/bin/goldfilter';
    }

    return {
      bundle: bundle,
      exe: exe,
      helperAppPath: helperAppPath
    };
  }

  static setPerm() {
    const {
      bundle,
      exe,
      helperAppPath
    } = GoldFilter._getPath();

    if (process.platform === 'linux') {
      try {
        const script = `cp ${bundle} ${exe} && setcap cap_net_raw,cap_net_admin=eip ${exe}`;
        if (childProcess.spawnSync('kdesudo', ['--help']).status === 0)
          childProcess.execFileSync('kdesudo', ['--', 'sh', '-c', script]);
        else if (childProcess.spawnSync('gksu', ['-h']).status === 0)
          childProcess.execFileSync('gksu', ['--sudo-mode', '--description', 'Dripcap', '--user', 'root', '--', 'sh', '-c', script]);
        else if (childProcess.spawnSync('pkexec', ['--help']).status === 0)
          childProcess.execFileSync('pkexec', ['sh', '-c', script]);
      } catch (err) {
        if (err.status === 126) {
          return false
        } else {
          throw err
        }
      }
    } else if (process.platform === 'darwin') {
      try {
        childProcess.execFileSync(helperAppPath)
      } catch (err) {
        try {
          const script = `mkdir /usr/local/lib ; cp ${bundle} ${exe}`;
          childProcess.execFileSync('osascript', ['-e', `do shell script \"${script}\" with administrator privileges`]);
        } catch (err) {
          if (err.status === -1) {
            return false
          } else {
            throw err
          }
        }
      }
    }
  }

  static testPerm() {
    if (process.env['DRIPCAP_UI_TEST'] != null) return true;

    const {
      bundle,
      exe
    } = GoldFilter._getPath();

    const digest = crypto.createHash('sha1').update(fs.readFileSync(bundle)).digest('hex');
    try {
      if (crypto.createHash('sha1').update(fs.readFileSync(exe)).digest('hex') != digest) {
        return false;
      }
      childProcess.execFileSync(exe, ['--test-perm']);
    } catch (err) {
      // console.warn(err);
      return false
    }
    return true;
  }

  setTestData(path) {
    return this._call('set_testdata', msgpack.decode(fs.readFileSync(path)));
  }

  saveTestData(path) {
    return this._getPackets(1, 1000).then((packets) => {
      let writeStream = fs.createWriteStream(path);
      let encodeStream = msgpack.createEncodeStream();
      encodeStream.pipe(writeStream);
      let obj = {
        packets: [],
        devices: []
      };
      for (let pkt of packets) {
        pkt.layers['::<Ethernet>'].layers = {};
        obj.packets.push(pkt);
      }

      obj.devices = [{
        name: 'en0',
        description: '',
        link: 1,
        loopback: false
      }];

      encodeStream.write(obj);
      encodeStream.end();

      return Promise.resolve();
    });
  }
}
