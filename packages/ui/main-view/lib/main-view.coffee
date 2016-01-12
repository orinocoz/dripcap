$ = require('jquery')
Component = require('dripcap/component')
Panel = require('dripcap/panel')

class MainView
  activate: ->
    new Promise (res) =>
      @_comp = new Component "#{__dirname}/../less/*.less"
      $ =>
        @panel = new Panel
        @_elem = $('<div id="main-view">').append(@panel.root)
        @_elem.appendTo $('body')
        res()

  updateTheme: (theme) ->
    @_comp.updateTheme theme

  deactivate: ->
    @_elem.remove()
    @_comp.destroy()

module.exports = MainView
