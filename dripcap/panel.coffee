$ = require('jquery')
_ = require('underscore')

$.fn.extend
  actualHeight: ->
    y = @.clone().css(position: 'absolute', visibility: 'hidden', display: 'block').appendTo $('body')
    height = y.height()
    y.remove()
    Math.max(height, @.height())

html = '
  <div class="panel root">
    <div class="panel fnorth"></div>
    <div class="panel fsouth"></div>
    <div class="hcontainer">
      <div class="panel left">
        <div class="tabcontainer"></div>
        <div class="panel fnorth"></div>
        <div class="panel fsouth"></div>
        <div class="vcontainer"></div>
      </div>
      <div class="panel hcenter">
        <div class="vcontainer">
          <div class="panel top">
            <div class="tabcontainer"></div>
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="panel vcenter">
            <div class="tabcontainer"></div>
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="panel bottom">
            <div class="tabcontainer"></div>
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
        <div class="tabcontainer"></div>
        <div class="panel fnorth"></div>
        <div class="panel fsouth"></div>
        <div class="vcontainer"></div>
      </div>
      <div class="splitter hsplitter"></div>
      <div class="splitter hsplitter"></div>
      <div class="hover hhover"></div>
      <div class="hover hhover"></div>
    </div>
  </div>
'

class Panel
  constructor: ->
    @root = $(html)
    @root.data 'panel', @

    @update = _.debounce () =>
      @_update()
    , 500

    $(window).resize => @_update()
    dripcap.package.sub 'core:package-loaded', => @update()

    @_hcontainer = @root.children '.hcontainer'
    @_fnorthPanel = @root.children '.fnorth'
    @_fsouthPanel = @root.children '.fsouth'
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
    @_centerPanel = @_vcontainer.children '.vcenter'
    @_fCenterNorthPanel = @_centerPanel.children '.fnorth'
    @_fCenterSouthPanel = @_centerPanel.children '.fsouth'
    @_bottomPanel = @_vcontainer.children '.bottom'
    @_fBottomNorthPanel = @_bottomPanel.children '.fnorth'
    @_fBottomSouthPanel = @_bottomPanel.children '.fsouth'
    @_vsp0 = @_vcontainer.children '.vsplitter:eq(0)'
    @_vsp1 = @_vcontainer.children '.vsplitter:eq(1)'
    @_vh0 = @_vcontainer.children '.vhover:eq(0)'
    @_vh1 = @_vcontainer.children '.vhover:eq(1)'

    @root.data 'v0', 0.0
    @root.data 'v1', 1.0
    @root.data 'h0', 0.0
    @root.data 'h1', 1.0

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

    @_vsp0.on 'mousedown', =>
      @_vh0.show()
      false

    @_vsp1.on 'mousedown', =>
      @_vh1.show()
      false

    @_hsp0.on 'mousedown', =>
      @_hh0.show()
      false

    @_hsp1.on 'mousedown', =>
      @_hh1.show()
      false

    @_vh0.on 'mousemove', (e) =>
      v = (e.clientY - @_vcontainer.offset().top) / @_vcontainer.height()
      v1 = @root.data('v1')
      if v < v1
        @root.data 'v0', v
        @_update()

    @_vh1.on 'mousemove', (e) =>
      v = (e.clientY - @_vcontainer.offset().top) / @_vcontainer.height()
      v0 = @root.data('v0')
      if v > v0
        @root.data 'v1', v
        @_update()

    @_hh0.on 'mousemove', (e) =>
      h = (e.clientX - @_hcontainer.offset().left) / @_hcontainer.width()
      h1 = @root.data('h1')
      if h < h1
        @root.data 'h0', h
        @_update()

    @_hh1.on 'mousemove', (e) =>
      h = (e.clientX - @_hcontainer.offset().left) / @_hcontainer.width()
      h0 = @root.data('h0')
      if h > h0
        @root.data 'h1', h
        @_update()

    @update()

  top: (id, elem, tab) ->
    container = @_topPanel.children('.vcontainer')
    res = container.children("[tab-id=#{id}]").detach()
    @_vsp0.toggle elem?
    unless elem?
      @root.data 'v0', 0.0
      res.removeAttr 'tab-id'
      @update()
      return res
    if @root.data('v1') == 1.0
      @root.data 'v0', 0.5
    else
      @root.data 'v0', 1 / 3
      @root.data 'v1', 2 / 3
    elem.attr 'tab-id', id
    elem.data('tab', tab) if tab?
    elem.detach().appendTo container
    @update()
    res

  topNorthFixed: (elem) ->
    res = @_fTopNorthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fTopNorthPanel
    @update()
    res

  topSouthFixed: (elem) ->
    res = @_fTopSouthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fTopSouthPanel
    @update()
    res

  northFixed: (elem) ->
    res = @_fnorthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fnorthPanel
    @update()
    res

  bottom: (id, elem, tab) ->
    container = @_bottomPanel.children('.vcontainer')
    res = container.children("[tab-id=#{id}]").detach()
    @_vsp1.toggle elem?
    unless elem?
      @root.data 'v1', 1.0
      res.removeAttr 'tab-id'
      @update()
      return res
    if @root.data('v0') == 0.0
      @root.data 'v1', 0.5
    else
      @root.data 'v0', 1 / 3
      @root.data 'v1', 2 / 3
    elem.attr 'tab-id', id
    elem.data('tab', tab) if tab?
    elem.detach().appendTo container
    @update()
    res

  bottomNorthFixed: (elem) ->
    res = @_fBottomNorthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fBottomNorthPanel
    @update()
    res

  bottomSouthFixed: (elem) ->
    res = @_fBottomSouthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fBottomSouthPanel
    @update()
    res

  southFixed: (elem) ->
    res = @_fsouthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fsouthPanel
    @update()
    res

  left: (id, elem, tab) ->
    container = @_leftPanel.children('.vcontainer')
    res = container.children("[tab-id=#{id}]").detach()
    @_hsp0.toggle elem?
    unless elem?
      @root.data 'h0', 0.0
      res.removeAttr 'tab-id'
      @update()
      return res
    if @root.data('h1') == 1.0
      @root.data 'h0', 0.5
    else
      @root.data 'h0', 1 / 3
      @root.data 'h1', 2 / 3
    elem.attr 'tab-id', id
    elem.data('tab', tab) if tab?
    elem.detach().appendTo container
    @update()
    res

  leftNorthFixed: (elem) ->
    res = @_fLeftNorthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fLeftNorthPanel
    @update()
    res

  leftSouthFixed: (elem) ->
    res = @_fLeftSouthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fLeftSouthPanel
    @update()
    res

  right: (id, elem, tab) ->
    container = @_rightPanel.children('.vcontainer')
    res = container.children("[tab-id=#{id}]").detach()
    @_hsp1.toggle elem?
    unless elem?
      @root.data 'h1', 1.0
      res.removeAttr 'tab-id'
      @update()
      return res
    if @root.data('h0') == 0.0
      @root.data 'h1', 0.5
    else
      @root.data 'h0', 1 / 3
      @root.data 'h1', 2 / 3
    elem.attr 'tab-id', id
    elem.data('tab', tab) if tab?
    elem.detach().appendTo container
    @update()
    res

  rightNorthFixed: (elem) ->
    res = @_fRightNorthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fRightNorthPanel
    @update()
    res

  rightSouthFixed: (elem) ->
    res = @_fRightSouthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fRightSouthPanel
    @update()
    res

  center: (id, elem, tab) ->
    container = @_centerPanel.children('.vcontainer')
    res = container.children("[tab-id=#{id}]").detach()
    unless elem?
      res.removeAttr 'tab-id'
      @update()
      return res
    elem.attr 'tab-id', id
    elem.data('tab', tab) if tab?
    elem.detach().appendTo container
    @update()
    res

  centerNorthFixed: (elem) ->
    res = @_fCenterNorthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fCenterNorthPanel
    @update()
    res

  centerSouthFixed: (elem) ->
    res = @_fCenterSouthPanel.children().detach()
    unless elem?
      @update()
      return res
    elem.detach().appendTo @_fCenterSouthPanel
    @update()
    res

  _update: ->
    v0 = @root.data('v0')
    v1 = @root.data('v1')
    h0 = @root.data('h0')
    h1 = @root.data('h1')

    @_topPanel.css 'bottom', (100 - v0 * 100) + '%'
    @_centerPanel.css 'top', (v0 * 100) + '%'
    @_centerPanel.css 'bottom', (100 - v1 * 100) + '%'
    @_bottomPanel.css 'top', (v1 * 100) + '%'
    @_vsp0.css 'top', (v0 * 100) + '%'
    @_vsp1.css 'top', (v1 * 100) + '%'

    @_leftPanel.css 'right', (100 - h0 * 100) + '%'
    @_hcenterPanel.css 'left', (h0 * 100) + '%'
    @_hcenterPanel.css 'right', (100 - h1 * 100) + '%'
    @_rightPanel.css 'left', (h1 * 100) + '%'
    @_hsp0.css 'left', (h0 * 100) + '%'
    @_hsp1.css 'left', (h1 * 100) + '%'

    update = (panel) ->
      panels = panel.children('.vcontainer').children('[tab-id]')
      currentId = panels.filter(-> $(@).css('display') != 'none').attr('tab-id')
      tabs = panels.get().map (elem) ->
        id = $(elem).attr('tab-id')
        tab = $('<div>')
          .addClass('tab')
          .text(id)
          .toggleClass('selected', currentId == id)
          .attr('tab-id', id)
          .click ->
            id = $(@).attr('tab-id')
            $(@).addClass('selected').siblings().removeClass('selected')
            $(@).parent().siblings('.vcontainer').children('[tab-id]').each (i, elem) ->
              $(elem).toggle($(elem).attr('tab-id') == id)

        if $(elem).data('tab')?
          tab.empty().append($(elem).data('tab').detach())

        tab

      panels.each (i, elem) ->
        $(elem).toggle($(elem).attr('tab-id') == currentId)

      tabcontainer = panel.children('.tabcontainer')
      tabcontainer.empty()
      tabcontainer.append(tabs) if tabs.length > 1

    @_hcontainer.css 'top', @_fnorthPanel.actualHeight() + 'px'
    @_hcontainer.css 'bottom', @_fsouthPanel.actualHeight() + 'px'

    update(@_leftPanel)
    @_leftPanel.children('.vcontainer')
      .css 'top', @_fLeftNorthPanel.actualHeight() + @_leftPanel.children('.tabcontainer').actualHeight() + 'px'
      .css 'bottom', @_fLeftSouthPanel.actualHeight() + 'px'

    update(@_rightPanel)
    @_rightPanel.children('.vcontainer')
      .css 'top', @_fRightNorthPanel.actualHeight() + @_rightPanel.children('.tabcontainer').actualHeight() + 'px'
      .css 'bottom', @_fRightSouthPanel.actualHeight() + 'px'

    update(@_topPanel)
    @_topPanel.children('.vcontainer')
      .css 'top', @_fTopNorthPanel.actualHeight() + @_topPanel.children('.tabcontainer').actualHeight() + 'px'
      .css 'bottom', @_fTopSouthPanel.actualHeight() + 'px'

    update(@_bottomPanel)
    @_bottomPanel.children('.vcontainer')
      .css 'top', @_fBottomNorthPanel.actualHeight() + @_bottomPanel.children('.tabcontainer').actualHeight() + 'px'
      .css 'bottom', @_fBottomSouthPanel.actualHeight() + 'px'

    update(@_centerPanel)
    @_centerPanel.children('.vcontainer')
      .css 'top', @_fCenterNorthPanel.actualHeight() + @_centerPanel.children('.tabcontainer').actualHeight() + 'px'
      .css 'bottom', @_fCenterSouthPanel.actualHeight() + 'px'

module.exports = Panel
