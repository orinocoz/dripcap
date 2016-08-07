import { EventEmitter } from 'events';
import GoldFilter from 'goldfilter';

export default class Session extends EventEmitter {
  constructor(_filterPath) {
    super();
    this._filterPath = _filterPath;
    this._timer = 0;
    this._gold = new GoldFilter();
    this._gold.on('packet', pkt => {
      return this.emit('packet', pkt);
    }
    );

    this._builtin = Promise.all([
      this.addClass('dripcap/mac', `${__dirname}/builtin/mac.es`),
      this.addClass('dripcap/enum', `${__dirname}/builtin/enum.es`),
      this.addClass('dripcap/flags', `${__dirname}/builtin/flags.es`),
      this.addClass('dripcap/ipv4/addr', `${__dirname}/builtin/ipv4/addr.es`),
      this.addClass('dripcap/ipv4/host', `${__dirname}/builtin/ipv4/host.es`),
      this.addClass('dripcap/ipv6/addr', `${__dirname}/builtin/ipv6/addr.es`),
      this.addClass('dripcap/ipv6/host', `${__dirname}/builtin/ipv6/host.es`)
    ]);
  }

  requestPackets(start, end) {
    return this._gold.requestPackets(start, end);
  }

  addCapture(iface, options = {}) {
    return this._settings = {iface, options};
  }

  addDissector(namespaces, path) {
    return this._gold.addDissector(namespaces, path);
  }

  addStreamDissector(namespaces, path) {
    return this._gold.addStreamDissector(namespaces, path);
  }

  addClass(name, path) {
    return this._gold.addClass(name, path);
  }

  setFilter(name, exp) {
    return this._gold.setFilter(name, exp);
  }

  getFiltered(name, start, end) {
    return this._gold.getFiltered(name, start, end);
  }

  start() {
    return this._gold.stop().then(() => {
      return this._builtin.then(() => {
        return this._gold.start(this._settings.iface, this._settings.options).then(() => {
          return this._timer = setInterval(() => {
            return this._gold.status().then(stat => {
              if (stat != null) {
                dripcap.pubsub.pub('core:capturing-status', stat.capturing);
                return this.emit('status', stat);
              }
            }
            );
          }
          , 100);
        }
        );
      }
      );
    }
    );
  }

  stop() {
    return this._gold.stop();
  }

  close() {
    clearInterval(this._timer);
    return this._gold.close();
  }
}
