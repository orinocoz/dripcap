$ = require('jquery')
riot = require('riot')
coffee = require('coffee-script')
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

    riot.parsers.js.coffeescript = (js) ->
      coffee.compile(js)

    for pattern in tags
      for tag in glob.sync(pattern)
        if tag.endsWith('.tag')
          data = fs.readFileSync(tag, encoding: 'utf8')
          code = riot.compile(data)
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
    @_root = $(html)
    @_root.data 'panel', @

    @_hcontainer = @_root.children '.hcontainer'
    @_fnorthPanel = @_root.children '.fnorth'
    @_fsouthPanel = @_root.children '.fsouth'
    @_leftPanel = @_hcontainer.children '.left'
    @_fLeftNorthPanel = @_leftPanel.children '.fnorth'
    @_fLeftSouthPanel = @_leftPanel.children '.fsouth'
    @_hcenterPanel = @_hcontainer.children '.hcenter'
    @_rightPanel = @_hcontainer.children '.right'
    @_fRightNorthPanel = @_rightPanel.children '.fnorth'
    @_fRightSouthPanel = @_rightPanel.children '.fsouth'
    @_hsp0 = @_hcontainer.children '.hsplitter:eq(0)'
    @_hsp1 = @_hcontainer.children '.hsplitter:eq(1)'
    @_hh0 = @_hcontainer.children '.hhover:eq(0)'
    @_hh1 = @_hcontainer.children '.hhover:eq(1)'

    @_vcontainer = @_hcenterPanel.children '.vcontainer'
    @_topPanel = @_vcontainer.children '.top'
    @_fTopNorthPanel = @_topPanel.children '.fnorth'
    @_fTopSouthPanel = @_topPanel.children '.fsouth'
    @_vcenterPanel = @_vcontainer.children '.vcenter'
    @_fCenterNorthPanel = @_vcenterPanel.children '.fnorth'
    @_fCenterSouthPanel = @_vcenterPanel.children '.fsouth'
    @_bottomPanel = @_vcontainer.children '.bottom'
    @_fBottomNorthPanel = @_bottomPanel.children '.fnorth'
    @_fBottomSouthPanel = @_bottomPanel.children '.fsouth'
    @_vsp0 = @_vcontainer.children '.vsplitter:eq(0)'
    @_vsp1 = @_vcontainer.children '.vsplitter:eq(1)'
    @_vh0 = @_vcontainer.children '.vhover:eq(0)'
    @_vh1 = @_vcontainer.children '.vhover:eq(1)'

    @_root.data 'v0', 0.0
    @_root.data 'v1', 1.0
    @_root.data 'h0', 0.0
    @_root.data 'h1', 1.0

    @_vh0.hide()
    @_vh1.hide()
    @_hh0.hide()
    @_hh1.hide()
    @_vsp0.hide()
    @_vsp1.hide()
    @_hsp0.hide()
    @_hsp1.hide()

    @_vh0.on 'mouseup mouseout', -> $(@).hide()
    @_vh1.on 'mouseup mouseout', -> $(@).hide()
    @_hh0.on 'mouseup mouseout', -> $(@).hide()
    @_hh1.on 'mouseup mouseout', -> $(@).hide()

    @_vsp0.on 'mousedown', => @_vh0.show()
    @_vsp1.on 'mousedown', => @_vh1.show()
    @_hsp0.on 'mousedown', => @_hh0.show()
    @_hsp1.on 'mousedown', => @_hh1.show()

    @_vh0.on 'mousemove', (e) =>
      v = (e.clientY - @_vcontainer.offset().top) / @_vcontainer.height()
      v1 = @_root.data('v1')
      if v < v1
        @_root.data 'v0', v
        @_update()

    @_vh1.on 'mousemove', (e) =>
      v = (e.clientY - @_vcontainer.offset().top) / @_vcontainer.height()
      v0 = @_root.data('v0')
      if v > v0
        @_root.data 'v1', v
        @_update()

    @_hh0.on 'mousemove', (e) =>
      h = (e.clientX - @_hcontainer.offset().left) / @_hcontainer.width()
      h1 = @_root.data('h1')
      if h < h1
        @_root.data 'h0', h
        @_update()

    @_hh1.on 'mousemove', (e) =>
      h = (e.clientX - @_hcontainer.offset().left) / @_hcontainer.width()
      h0 = @_root.data('h0')
      if h > h0
        @_root.data 'h1', h
        @_update()

    @_update()

  top: (elem) ->
    container = @_topPanel.children('.vcontainer')
    res = container.children().detach()
    @_vsp0.toggle elem?
    unless elem?
      @_root.data 'v0', 0.0
      return res
    if @_root.data('v1') == 1.0
      @_root.data 'v0', 0.5
    else
      @_root.data 'v0', 1 / 3
      @_root.data 'v1', 2 / 3
    elem.detach().appendTo container
    @_update()
    res

  topNorthFixed: (elem) ->
    res = @_fTopNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fTopNorthPanel
    @_update()
    res

  topSouthFixed: (elem) ->
    res = @_fTopSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fTopSouthPanel
    @_update()
    res

  northFixed: (elem) ->
    res = @_fnorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fnorthPanel
    @_update()
    res

  bottom: (elem) ->
    container = @_bottomPanel.children('.vcontainer')
    res = container.children().detach()
    @_vsp1.toggle elem?
    unless elem?
      @_root.data 'v1', 1.0
      return res
    if @_root.data('v0') == 0.0
      @_root.data 'v1', 0.5
    else
      @_root.data 'v0', 1 / 3
      @_root.data 'v1', 2 / 3
    elem.detach().appendTo container
    @_update()
    res

  bottomNorthFixed: (elem) ->
    res = @_fBottomNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fBottomNorthPanel
    @_update()
    res

  bottomSouthFixed: (elem) ->
    res = @_fBottomSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fBottomSouthPanel
    @_update()
    res

  southFixed: (elem) ->
    res = @_fsouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fsouthPanel
    @_update()
    res

  left: (elem) ->
    container = @_leftPanel.children('.vcontainer')
    res = container.children().detach()
    @_hsp0.toggle elem?
    unless elem?
      @_root.data 'h0', 0.0
      return res
    if @_root.data('h1') == 1.0
      @_root.data 'h0', 0.5
    else
      @_root.data 'h0', 1 / 3
      @_root.data 'h1', 2 / 3
    elem.detach().appendTo container
    @_update()
    res

  leftNorthFixed: (elem) ->
    res = @_fLeftNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fLeftNorthPanel
    @_update()
    res

  leftSouthFixed: (elem) ->
    res = @_fLeftSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fLeftSouthPanel
    @_update()
    res

  right: (elem) ->
    container = @_rightPanel.children('.vcontainer')
    res = container.children().detach()
    @_hsp1.toggle elem?
    unless elem?
      @_root.data 'h1', 1.0
      return res
    if @_root.data('h0') == 0.0
      @_root.data 'h1', 0.5
    else
      @_root.data 'h0', 1 / 3
      @_root.data 'h1', 2 / 3
    elem.detach().appendTo container
    @_update()
    res

  rightNorthFixed: (elem) ->
    res = @_fRightNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fRightNorthPanel
    @_update()
    res

  rightSouthFixed: (elem) ->
    res = @_fRightSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fRightSouthPanel
    @_update()
    res

  center: (elem) ->
    container = @_vcenterPanel.children('.vcontainer')
    res = container.children().detach()
    unless elem?
      return res
    elem.detach().appendTo container
    @_update()
    res

  centerNorthFixed: (elem) ->
    res = @_fCenterNorthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fCenterNorthPanel
    @_update()
    res

  centerSouthFixed: (elem) ->
    res = @_fCenterSouthPanel.children().detach()
    unless elem?
      return res
    elem.detach().appendTo @_fCenterSouthPanel
    @_update()
    res

  _update: ->
    v0 = @_root.data('v0')
    v1 = @_root.data('v1')
    h0 = @_root.data('h0')
    h1 = @_root.data('h1')

    @_topPanel.css 'bottom', (100 - v0 * 100) + '%'
    @_vcenterPanel.css 'top', (v0 * 100) + '%'
    @_vcenterPanel.css 'bottom', (100 - v1 * 100) + '%'
    @_bottomPanel.css 'top', (v1 * 100) + '%'
    @_vsp0.css 'top', (v0 * 100) + '%'
    @_vsp1.css 'top', (v1 * 100) + '%'

    @_leftPanel.css 'right', (100 - h0 * 100) + '%'
    @_hcenterPanel.css 'left', (h0 * 100) + '%'
    @_hcenterPanel.css 'right', (100 - h1 * 100) + '%'
    @_rightPanel.css 'left', (h1 * 100) + '%'
    @_hsp0.css 'left', (h0 * 100) + '%'
    @_hsp1.css 'left', (h1 * 100) + '%'

    @_hcontainer.css 'top', @_fnorthPanel.height() + 'px'
    @_hcontainer.css 'bottom', @_fsouthPanel.height() + 'px'

    @_leftPanel.children('.vcontainer')
      .css 'top', @_fLeftNorthPanel.height() + 'px'
      .css 'bottom', @_fLeftSouthPanel.height() + 'px'

    @_rightPanel.children('.vcontainer')
      .css 'top', @_fRightNorthPanel.height() + 'px'
      .css 'bottom', @_fRightSouthPanel.height() + 'px'

    @_topPanel.children('.vcontainer')
      .css 'top', @_fRightNorthPanel.height() + 'px'
      .css 'bottom', @_fRightSouthPanel.height() + 'px'

    @_topPanel.children('.vcontainer')
      .css 'top', @_fTopNorthPanel.height() + 'px'
      .css 'bottom', @_fTopSouthPanel.height() + 'px'

    @_bottomPanel.children('.vcontainer')
      .css 'top', @_fBottomNorthPanel.height() + 'px'
      .css 'bottom', @_fBottomSouthPanel.height() + 'px'

    @_vcenterPanel.children('.vcontainer')
      .css 'top', @_fCenterNorthPanel.height() + 'px'
      .css 'bottom', @_fCenterSouthPanel.height() + 'px'

exports.Panel = Panel
