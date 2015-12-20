class Layer
  constructor: (@namespace, params) ->
    @name = params.name ? @namespace
    @aliases = params.aliases ? []
    @payloadOffset = params.payloadOffset ? 0
    @fields = params.fields ? []
    @attrs = params.attrs ? {}
    @data = params.data ? {}

    @summary = params.summary if params.summary?
    @error = params.error if params.error?
    @payload = params.payload if params.payload?

    makeAttrs = (fields) =>
      for f in fields
        @attrs[f.attr] = f.value if f.attr?
        makeAttrs f.fields if f.fields?

    makeAttrs @fields

module.exports = Layer
