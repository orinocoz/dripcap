$ = require('jquery')
_ = require('underscore')
Mousetrap = require('mousetrap')
{EventEmitter} = require('events')

class KeybindInterface extends EventEmitter
  constructor: (@parent) ->
    @_builtinCommands = {}
    @_commands = {}

  bind: (command, selector, act) ->
    @_builtinCommands[command] ?= {}
    @_builtinCommands[command][selector] = act
    @_update()

  unbind: (command, selector, act) ->
    if (@_builtinCommands[command]?[selector] == act)
      delete @_builtinCommands[command][selector]
      if Object.keys(@_builtinCommands[command]) == 0
        delete @_builtinCommands[command]
    @_update()

  get: (selector, action) ->
    for sel, commands of dripcap.profile.getKeymap()
      for command, act of commands
        if sel == selector && act == action
          if process.platform == 'linux'
            return command.replace 'command', 'ctrl'
          else
            return command

    for command, sels of @_commands
      for sel, act of sels
        if sel == selector && act == action
          if process.platform == 'linux'
            return command.replace 'command', 'ctrl'
          else
            return command
    null

  _update: ->
    Mousetrap.reset()

    @_commands = _.clone @_builtinCommands
    for selector, commands of dripcap.profile.getKeymap()
      for command, act of commands
        @_commands[command] ?= {}
        @_commands[command][selector] = act

    for command, sels of @_commands
      do (command, sels) =>
        if process.platform == 'linux'
          command = command.replace 'command', 'ctrl'
        Mousetrap.bind command, (e) =>
          for sel, act of @_commands[command]
            unless sel.startsWith '!'
              if $(e.target).is(sel) || $(e.target).parents(sel).length
                if _.isFunction act
                  act(e)
                else
                  dripcap.action.emit act

    @emit 'update'

module.exports = KeybindInterface
