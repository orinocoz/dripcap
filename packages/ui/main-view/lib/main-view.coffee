$ = require('jquery')
{Component, Panel} = require('dripper/component')


class MainView
  activate: ->
    @comp = new Component "#{__dirname}/../less/*.less"
    $ =>
      panel = new Panel
      panel.right($('<a></a>'))
      @elem = $('<div id="main-view">').append(panel.root)
      @elem.appendTo $('body')

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    @elem.remove()
    @comp.destroy()

module.exports = MainView
