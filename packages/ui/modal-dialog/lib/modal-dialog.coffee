$ = require('jquery')
riot = require('riot')
{Component} = require('dripcap/component')

class ModalDialog
  activate: ->
    @comp = new Component "#{__dirname}/../tag/*.tag"

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @comp.destroy()

module.exports = ModalDialog
