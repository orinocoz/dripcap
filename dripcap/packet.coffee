Layer = require('./layer')

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

leafLayer = (layer) ->
  if layer.layers?
    ns = Object.keys layer.layers
    if ns.length > 0
      return leafLayer layer.layers[ns[0]]
  layer

class Packet
  constructor: (data) ->
    for k, v of data
      @[k] = v

  addLayer: (namespace, params) ->
    @layers.push new Layer(namespace, params)

  @property 'namespace', get: ->
    throw new Error 'empty packet' if Object.keys(@layers).length == 0
    layer = leafLayer @layers[Object.keys(@layers)[0]]
    return layer.namespace if layer.namespace?

  @property 'name', get: ->
    throw new Error 'empty packet' if Object.keys(@layers).length == 0
    layer = leafLayer @layers[Object.keys(@layers)[0]]
    return layer.name if layer.name?

  @property 'attrs', get: ->
    throw new Error 'empty packet' if Object.keys(@layers).length == 0
    attrs = {}
    getAttrs = (layers) ->
      for _, layer of layers
        for k, v of layer.attrs ? {}
          attrs[k] = v
        getAttrs layer.layers ? {}
    getAttrs @layers
    attrs

module.exports = Packet
