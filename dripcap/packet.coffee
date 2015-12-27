Layer = require('./layer')

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

class Packet
  constructor: (data) ->
    for k, v of data
      @[k] = v

  addLayer: (namespace, params) ->
    @layers.push new Layer(namespace, params)

  @property 'namespace', get: ->
    throw new Error 'empty packet' if @layers.length == 0
    for layer in @layers.slice(0).reverse()
      return layer.namespace if layer.namespace?
      
  @property 'name', get: ->
    throw new Error 'empty packet' if @layers.length == 0
    for layer in @layers.slice(0).reverse()
      return layer.name if layer.name?

  @property 'attrs', get: ->
    throw new Error 'empty packet' if @layers.length == 0
    attrs = {}
    for layer in @layers
      if layer.attrs?
        for k, v of layer.attrs
          attrs[k] = v
    attrs

module.exports = Packet
