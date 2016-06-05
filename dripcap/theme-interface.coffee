PubSub = require('./pubsub')

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

class ThemeInterface extends PubSub
  constructor: (@parent) ->
    super()
    @registry = {}

    @_defaultScheme =
      name: 'Default'
      less: ["#{__dirname}/theme.less"]

    @register 'default', @_defaultScheme
    @id = 'default'

  register: (id, scheme) ->
    @registry[id] = scheme
    @pub 'registryUpdated', null, 1
    if @_id == id
      @scheme = @registry[id]
      @pub 'update', @scheme, 1

  unregister: (id) ->
    delete @registry[id]
    @pub 'registryUpdated', null, 1

  @property 'id',
    get: -> @_id
    set: (id) ->
      if id != @_id
        @_id = id
        @parent.profile.setConfig 'theme', id
        if @registry[id]?
          @scheme = @registry[id]
          @pub 'update', @scheme, 1

module.exports = ThemeInterface
