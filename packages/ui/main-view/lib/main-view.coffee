$ = require('jquery')
{Component, Panel} = require('dripper/component')


class MainView
  activate: ->
    @_comp = new Component "#{__dirname}/../less/*.less"
    $ =>
      @panel = new Panel
      @_elem = $('<div id="main-view">').append(@panel.root)
      @_elem.appendTo $('body')

    if process.platform == 'darwin'
      dripcap.event.on 'enter-full-screen', =>
        @_elem.css('top', '36px')

      dripcap.event.on 'leave-full-screen', =>
        @_elem.css('top', '0')

  updateTheme: (theme) ->
    @_comp.updateTheme theme

  deactivate: ->
    @_elem.remove()
    @_comp.destroy()

module.exports = MainView
