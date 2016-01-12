$ = require('jquery')
riot = require('riot')
less = require('less')
fs = require('fs')
glob = require('glob')

tagPattern = /riot\.tag\('([a-z-]+)'/ig

class Component
  constructor: (tags...) ->
    @_less = ''
    @_names = []

    riot.parsers.css.less = (tag, css) =>
      @_less += css
      ''

    for pattern in tags
      for tag in glob.sync(pattern)
        if tag.endsWith('.tag')
          data = fs.readFileSync(tag, encoding: 'utf8')
          code = "riot = require('riot');\n" + riot.compile(data)
          while match = tagPattern.exec code
            @_names.push match[1]
          new Function(code)()

        else if tag.endsWith('.less')
          @_less += "@import \"#{tag}\";\n"

    @_css = $('<style>').appendTo $('head')

  updateTheme: (theme) ->
    compLess = @_less
    if compLess?
      if theme.less?
        for l in theme.less
          compLess += "@import \"#{l}\";\n"

      less.render compLess, (e, output) =>
        if e?
          throw e
        else
          @_css.text output.css

  destroy: ->
    for name in @_names
      riot.tag name, ''
    @_css.remove()

module.exports = Component
