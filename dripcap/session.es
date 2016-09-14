import {
  EventEmitter
} from 'events';
import GoldFilter from 'goldfilter';

export default class Session extends EventEmitter {
  constructor(_filterPath) {
    super();
    this._filterPath = _filterPath;
    this._timer = 0;
    this._gold = new GoldFilter();
    this._gold.on('packet', pkt => {
      return this.emit('packet', pkt);
    });

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
    this._settings = {
      iface,
      options
    };
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

  async start() {
    await this._gold.stop();
    await this._builtin;
    if (this._settings != null) {
      await this._gold.start(this._settings.iface, this._settings.options);
    }
    this._timer = setInterval(() => {
      this._gold.status().then(stat => {
        if (stat != null) {
          this.emit('status', stat);
        }
      });
    }, 100);

    this._logTimer = setInterval(() => {
      this._gold.logs().then(log => {
        if (log.length > 0) {
          this.emit('log', log);
        }
      });
    }, 1000);
  }

  stop() {
    return this._gold.stop();
  }

  close() {
    clearInterval(this._timer);
    clearInterval(this._logTimer);
    return this._gold.close();
  }
}
