$ = require('jquery')
riot = require('riot')
coffee = require('coffee-script')
less = require('less')
fs = require('fs')
glob = require('glob')

tagPattern = /riot\.tag\('([a-z-]+)'/ig

class Component
  constructor: (tags...) ->
    @less = ''
    @names = []

    riot.parsers.css.less = (tag, css) =>
      @less += css
      ''

    riot.parsers.js.coffeescript = (js) ->
      coffee.compile(js)

    for pattern in tags
      for tag in glob.sync(pattern)
        if tag.endsWith('.tag')
          data = fs.readFileSync(tag, encoding: 'utf8')
          code = riot.compile(data)
          while match = tagPattern.exec code
            @names.push match[1]
          new Function(code)()

        else if tag.endsWith('.less')
          @less += "@import \"#{tag}\";\n"

    @css = $('<style>').appendTo $('head')

  updateTheme: (theme) ->
    compLess = @less
    if compLess?
      if theme.less?
        for l in theme.less
          compLess += "@import \"#{l}\";\n"

      less.render compLess, (e, output) =>
        if e?
          throw e
        else
          @css.text output.css

  destroy: ->
    for name in @names
      riot.tag name, ''
    @css.remove()

exports.Component = Component

html = '
  <div class="panel root">
    <div class="panel fnorth"></div>
    <div class="panel fsouth"></div>
    <div class="hcontainer">
      <div class="panel left">
        <div class="panel fnorth"></div>
        <div class="panel fsouth"></div>
        <div class="vcontainer"></div>
      </div>
      <div class="panel hcenter">
        <div class="vcontainer">
          <div class="panel top">
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="panel vcenter">
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="panel bottom">
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="splitter vsplitter"></div>
          <div class="splitter vsplitter"></div>
          <div class="hover vhover"></div>
          <div class="hover vhover"></div>
        </div>
      </div>
      <div class="panel right">
        <div class="panel fnorth"></div>
        <div class="panel fsouth"></div>
        <div class="vcontainer"></div>
      </div>
      <div class="splitter hsplitter"></div>
      <div class="splitter hsplitter"></div>
      <div class="hover hhover"></div>
      <div class="hover hhover"></div>
    </div>
    <div class="panel fleft"></div>
    <div class="panel fright"></div>
  </div>
'

class Panel
  constructor: ->
    @root = $(html)
    @root.data 'panel', @

    @hcontainer = @root.children '.hcontainer'
    @fnorthPanel = @root.children '.fnorth'
    @fsouthPanel = @root.children '.fsouth'
    @leftPanel = @hcontainer.children '.left'
    @fLeftNorthPanel = @leftPanel.children '.fnorth'
    @fLeftSouthPanel = @leftPanel.children '.fsouth'
    @hcenterPanel = @hcontainer.children '.hcenter'
    @rightPanel = @hcontainer.children '.right'
    @fRightNorthPanel = @rightPanel.children '.fnorth'
    @fRightSouthPanel = @rightPanel.children '.fsouth'
    @hsp0 = @hcontainer.children '.hsplitter:eq(0)'
    @hsp1 = @hcontainer.children '.hsplitter:eq(1)'
    @hh0 = @hcontainer.children '.hhover:eq(0)'
    @hh1 = @hcontainer.children '.hhover:eq(1)'

    @vcontainer = @hcenterPanel.children '.vcontainer'
    @topPanel = @vcontainer.children '.top'
    @fTopNorthPanel = @topPanel.children '.fnorth'
    @fTopSouthPanel = @topPanel.children '.fsouth'
    @vcenterPanel = @vcontainer.children '.vcenter'
    @fCenterNorthPanel = @vcenterPanel.children '.fnorth'
    @fCenterSouthPanel = @vcenterPanel.children '.fsouth'
    @bottomPanel = @vcontainer.children '.bottom'
    @fBottomNorthPanel = @bottomPanel.children '.fnorth'
    @fBottomSouthPanel = @bottomPanel.children '.fsouth'
    @vsp0 = @vcontainer.children '.vsplitter:eq(0)'
    @vsp1 = @vcontainer.children '.vsplitter:eq(1)'
    @vh0 = @vcontainer.children '.vhover:eq(0)'
    @vh1 = @vcontainer.children '.vhover:eq(1)'

    @root.data 'v0', 0.0
    @root.data 'v1', 1.0
    @root.data 'h0', 0.0
    @root.data 'h1', 1.0

    @vh0.hide()
    @vh1.hide()
    @hh0.hide()
    @hh1.hide()
    @vsp0.hide()
    @vsp1.hide()
    @hsp0.hide()
    @hsp1.hide()

    @vh0.on 'mouseup mouseout', -> $(@).hide()
    @vh1.on 'mouseup mouseout', -> $(@).hide()
    @hh0.on 'mouseup mouseout', -> $(@).hide()
    @hh1.on 'mouseup mouseout', -> $(@).hide()

    @vsp0.on 'mousedown', => @vh0.show()
    @vsp1.on 'mousedown', => @vh1.show()
    @hsp0.on 'mousedown', => @hh0.show()
    @hsp1.on 'mousedown', => @hh1.show()

    @vh0.on 'mousemove', (e) =>
      v = (e.clientY - @vcontainer.offset().top) / @vcontainer.height()
      v1 = @root.data('v1')
      if v < v1
        @root.data 'v0', v
        @update()

    @vh1.on 'mousemove', (e) =>
      v = (e.clientY - @vcontainer.offset().top) / @vcontainer.height()
      v0 = @root.data('v0')
      if v > v0
        @root.data 'v1', v
        @update()

    @hh0.on 'mousemove', (e) =>
      h = (e.clientX - @hcontainer.offset().left) / @hcontainer.width()
      h1 = @root.data('h1')
      if h < h1
        @root.data 'h0', h
        @update()

    @hh1.on 'mousemove', (e) =>
      h = (e.clientX - @hcontainer.offset().left) / @hcontainer.width()
      h0 = @root.data('h0')
      if h > h0
        @root.data 'h1', h
        @update()

    @update()

  top: (elem) ->
    container = @topPanel.children('.vcontainer')
    res = container.children().detach()
    @vsp0.toggle elem?
    unless elem?
      @root.data 'v0', 0.0
      return res
    if @root.data('v1') == 1.0
      @root.data 'v0', 0.5
    else
      @root.data 'v0', 1 / 3
      @root.data 'v1', 2 / 3
    elem.detach().appendTo container
    @update()
    res

  topNorthFixed: (elem) ->
    res = @fTopNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fTopNorthPanel
    @update()
    res

  topSouthFixed: (elem) ->
    res = @fTopSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fTopSouthPanel
    @update()
    res

  northFixed: (elem) ->
    res = @fnorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fnorthPanel
    @update()
    res

  bottom: (elem) ->
    container = @bottomPanel.children('.vcontainer')
    res = container.children().detach()
    @vsp1.toggle elem?
    unless elem?
      @root.data 'v1', 1.0
      return res
    if @root.data('v0') == 0.0
      @root.data 'v1', 0.5
    else
      @root.data 'v0', 1 / 3
      @root.data 'v1', 2 / 3
    elem.detach().appendTo container
    @update()
    res

  bottomNorthFixed: (elem) ->
    res = @fBottomNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fBottomNorthPanel
    @update()
    res

  bottomSouthFixed: (elem) ->
    res = @fBottomSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fBottomSouthPanel
    @update()
    res

  southFixed: (elem) ->
    res = @fsouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fsouthPanel
    @update()
    res

  left: (elem) ->
    container = @leftPanel.children('.vcontainer')
    res = container.children().detach()
    @hsp0.toggle elem?
    unless elem?
      @root.data 'h0', 0.0
      return res
    if @root.data('h1') == 1.0
      @root.data 'h0', 0.5
    else
      @root.data 'h0', 1 / 3
      @root.data 'h1', 2 / 3
    elem.detach().appendTo container
    @update()
    res

  leftNorthFixed: (elem) ->
    res = @fLeftNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fLeftNorthPanel
    @update()
    res

  leftSouthFixed: (elem) ->
    res = @fLeftSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fLeftSouthPanel
    @update()
    res

  right: (elem) ->
    container = @rightPanel.children('.vcontainer')
    res = container.children().detach()
    @hsp1.toggle elem?
    unless elem?
      @root.data 'h1', 1.0
      return res
    if @root.data('h0') == 0.0
      @root.data 'h1', 0.5
    else
      @root.data 'h0', 1 / 3
      @root.data 'h1', 2 / 3
    elem.detach().appendTo container
    @update()
    res

  rightNorthFixed: (elem) ->
    res = @fRightNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fRightNorthPanel
    @update()
    res

  rightSouthFixed: (elem) ->
    res = @fRightSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fRightSouthPanel
    @update()
    res

  center: (elem) ->
    container = @vcenterPanel.children('.vcontainer')
    res = container.children().detach()
    unless elem?
      return res
    elem.detach().appendTo container
    @update()
    res

  centerNorthFixed: (elem) ->
    res = @fCenterNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fCenterNorthPanel
    @update()
    res

  centerSouthFixed: (elem) ->
    res = @fCenterSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @fCenterSouthPanel
    @update()
    res

  update: ->
    v0 = @root.data('v0')
    v1 = @root.data('v1')
    h0 = @root.data('h0')
    h1 = @root.data('h1')

    @topPanel.css 'bottom', (100 - v0 * 100) + '%'
    @vcenterPanel.css 'top', (v0 * 100) + '%'
    @vcenterPanel.css 'bottom', (100 - v1 * 100) + '%'
    @bottomPanel.css 'top', (v1 * 100) + '%'
    @vsp0.css 'top', (v0 * 100) + '%'
    @vsp1.css 'top', (v1 * 100) + '%'

    @leftPanel.css 'right', (100 - h0 * 100) + '%'
    @hcenterPanel.css 'left', (h0 * 100) + '%'
    @hcenterPanel.css 'right', (100 - h1 * 100) + '%'
    @rightPanel.css 'left', (h1 * 100) + '%'
    @hsp0.css 'left', (h0 * 100) + '%'
    @hsp1.css 'left', (h1 * 100) + '%'

    @hcontainer.css 'top', @fnorthPanel.height() + 'px'
    @hcontainer.css 'bottom', @fsouthPanel.height() + 'px'

    @leftPanel.children('.vcontainer')
      .css 'top', @fLeftNorthPanel.height() + 'px'
      .css 'bottom', @fLeftSouthPanel.height() + 'px'

    @rightPanel.children('.vcontainer')
      .css 'top', @fRightNorthPanel.height() + 'px'
      .css 'bottom', @fRightSouthPanel.height() + 'px'

    @topPanel.children('.vcontainer')
      .css 'top', @fRightNorthPanel.height() + 'px'
      .css 'bottom', @fRightSouthPanel.height() + 'px'

    @topPanel.children('.vcontainer')
      .css 'top', @fTopNorthPanel.height() + 'px'
      .css 'bottom', @fTopSouthPanel.height() + 'px'

    @bottomPanel.children('.vcontainer')
      .css 'top', @fBottomNorthPanel.height() + 'px'
      .css 'bottom', @fBottomSouthPanel.height() + 'px'

    @vcenterPanel.children('.vcontainer')
      .css 'top', @fCenterNorthPanel.height() + 'px'
      .css 'bottom', @fCenterSouthPanel.height() + 'px'

exports.Panel = Panel
