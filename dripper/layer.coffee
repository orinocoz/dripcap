class Layer
  constructor: (@namespace, params) ->
    @name = params.name if params.name?
    @aliases = params.aliases if params.aliases?
    @summary = params.summary if params.summary?
    @error = params.error if params.error?
    @payload = params.payload if params.payload?
    @payloadOffset = params.payloadOffset if params.payloadOffset?
    @fields = params.fields if params.fields?
    @attrs = params.attrs if params.attrs?
    @data = params.data if params.data?
    @name ?= @namespace
    @aliases ?= []
    @payloadOffset ?= 0
    @fields ?= []
    @attrs ?= {}
    @data ?= {}

    makeAttrs = (fields) =>
      for f in fields
        @attrs[f.attr] = f.value if f.attr?
        makeAttrs f.fields if f.fields?

    makeAttrs @fields

module.exports = Layer
