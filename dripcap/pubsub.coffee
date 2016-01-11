class PubSub
  constructor: ->
    @_channels = {}

  _getChannel: (name) ->
    unless @_channels[name]?
      @_channels[name] = {queue: [], handlers: []}
    @_channels[name]

  sub: (name, cb) ->
    ch = @_getChannel name
    ch.handlers.push cb
    for data in ch.queue
      do (data) ->
        process.nextTick ->
          cb data

  pub: (name, data, queue=0) ->
    ch = @_getChannel name
    for cb in ch.handlers
      do (cb) ->
        process.nextTick ->
          cb data
    ch.queue.push data
    if queue > 0 && ch.queue.length > queue
      ch.queue.splice 0, ch.queue.length - queue

  get: (name, index = 0) ->
    ch = @_getChannel name
    ch.queue[ch.queue.length - index - 1]

module.exports = PubSub
