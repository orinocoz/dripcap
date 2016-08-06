$ = require('jquery')
riot = require('riot')
Component = require('dripcap/component')

class ModalDialog
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"

  deactivate: ->
    @comp.destroy()

module.exports = ModalDialog
