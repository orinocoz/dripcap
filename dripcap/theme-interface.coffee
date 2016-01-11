PubSub = require('./pubsub')

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

class ThemeInterface extends PubSub
  constructor: (@parent) ->
    super()
    @registory = {}

    @_defaultScheme =
      name: 'Default'
      less: ["#{__dirname}/theme.less"]

    @register 'default', @_defaultScheme
    @id = 'default'

  register: (id, scheme) ->
    @registory[id] = scheme
    @pub 'registoryUpdated', null, 1
    if @_id == id
      @scheme = @registory[id]
      @pub 'update', @scheme, 1

  unregister: (id) ->
    delete @registory[id]
    @pub 'registoryUpdated', null, 1

  @property 'id',
    get: -> @_id
    set: (id) ->
      if id != @_id
        @_id = id
        @parent.profile.setConfig 'theme', id
        if @registory[id]?
          @scheme = @registory[id]
          @pub 'update', @scheme, 1

module.exports = ThemeInterface
