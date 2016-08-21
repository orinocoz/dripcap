import util from 'util';

export default class LoggerInterface {
  constructor(parent) {
    this.parent = parent;
  }

  debug() {
    let msg = util.format.apply(this, arguments);
    this.parent.pubsub.pub('core:log', {
      level: 'debug',
      message: msg,
      timestamp: new Date()
    })
  }

  info() {
    let msg = util.format.apply(this, arguments);
    this.parent.pubsub.pub('core:log', {
      level: 'info',
      message: msg,
      timestamp: new Date()
    })
  }

  warn() {
    let msg = util.format.apply(this, arguments);
    this.parent.pubsub.pub('core:log', {
      level: 'warn',
      message: msg,
      timestamp: new Date()
    })
  }

  error() {
    let msg = util.format.apply(this, arguments);
    this.parent.pubsub.pub('core:log', {
      level: 'error',
      message: msg,
      timestamp: new Date()
    })
  }
}
