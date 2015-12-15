export default class PubSub {
  constructor() {
    this._channels = {}
  }

  _getChannel(name) {
    if (this._channels[name] == null) {
      this._channels[name] = {queue: [], handlers: []}
    }
    return this._channels[name]
  }

  sub(name, cb) {
    let ch = this._getChannel(name)
    ch.handlers.push(cb)
    for (let data of ch.queue) {
      ((data) => {
        process.nextTick(() => cb(data))
      })(data)
    }
  }

  pub(name, data, queue=0) {
    let ch = this._getChannel(name)
    for (let cb of ch.handlers) {
      ((cb) => {
        process.nextTick(() => cb(data))
      })(cb)
    }
    ch.queue.push(data)
    if (queue > 0 && ch.queue.length > queue) {
      ch.queue.splice(0, ch.queue.length - queue)
    }  
  }

  get(name, index = 0) {
    let ch = this._getChannel(name)
    return ch.queue[index]
  }
}
