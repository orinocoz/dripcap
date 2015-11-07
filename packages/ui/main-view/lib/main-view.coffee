$ = require('jquery')
{Component, Panel} = require('dripper/component')


class MainView
  activate: ->
    @_comp = new Component "#{__dirname}/../less/*.less"
    $ =>
      @panel = new Panel
      @_elem = $('<div id="main-view">').append(@panel.root)
      @_elem.appendTo $('body')

  updateTheme: (theme) ->
    @_comp.updateTheme theme

  deactivate: ->
    @_elem.remove()
    @_comp.destroy()

module.exports = MainView
