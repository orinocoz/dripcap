<packet-list-view-header>
  <div class="container"><i>Name</i></div>
  <div class="slider"></div>
  <div class="container"><i>Source</i></div>
  <div class="slider"></div>
  <div class="container"><i>Destination</i></div>
  <div class="slider"></div>
  <div class="container"><i>Legnth</i></div>
  <div class="hover-slider"></div>

  <style type="text/less">

  [riot-tag=packet-list-view-header] {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    padding: 10px 15px 10px 10px;
    margin-right: 12px;

    background: -webkit-gradient(linear,
      left top,
      left bottom,
      from(@background),
      color-stop(0.7, @background),
      to(fade(@background, 0%)));

    .container {
      flex: 1;
      cursor: default;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      font-weight: bold;
      color: @label;
      i {
        font-style: normal;
        padding: 0 10px;
      }
    }

    @splitter: fade(@scroll-bar, 40%);

    .slider {
      width: 1px;
      padding: 0 1px;
      cursor: col-resize;
      background-color: @splitter;
      background-clip: content-box;
    }

    .hover-slider
    {
      position: absolute;
      top: 0; right: 0; bottom: 0; left: 0;
      z-index: 100;
      cursor: col-resize;
      display: none;
    }
  }
  </style>

  <script type="text/coffeescript">

  @on 'mount', =>
    hover = $(@root).find('.hover-slider')
    $(@root).find('.slider').on 'mousedown', ->
      hover.data('slider', $(@)).show()
    hover.on 'mouseup mouseout', ->
      $(@).hide()

    root = $(@root)
    self = @
    hover.on 'mousemove', (e) ->
      slider = $(@).data('slider')
      prev = slider.prevAll('.container').first()
      next = slider.nextAll('.container').first()

      left = prev.position().left
      right = left + prev.width() + next.width()
      ratio = (e.clientX - left) / (right - left)
      sum = parseFloat(prev.css('flex-grow')) +
        parseFloat(next.css('flex-grow'))
      prev.css('flex-grow', ratio * sum)
      next.css('flex-grow', (1.0 - ratio) * sum)
      self.calculate()

    width = [0.6, 1.3, 1.3, 0.6]
    $(@root).children('.container').each (i, elem) ->
      $(elem).css 'flex-grow', width[i]

    @calculate()

  @calculate = =>
    con = $(@root).children('.container')

    sum = 0
    con.each ->
      sum += $(@).width()

    thMain = $('[riot-tag=packet-list-view] table.main th')
    thSub = $('[riot-tag=packet-list-view] table.sub th')
    con.each (i) ->
      $(thMain[i]).css 'width', ($(@).width() / sum * 100) + '%'
      $(thSub[i]).css 'width', ($(@).width() / sum * 100) + '%'

  </script>
</packet-list-view-header>

<packet-list-view>

  <table class="main">
    <tbody>
      <tr class="head"><th></th><th></th><th></th><th></th></tr>
    </tbody>
  </table>

  <table class="sub">
    <tbody>
      <tr class="head"><th></th><th></th><th></th><th></th></tr>
    </tbody>
  </table>

  <style type="text/less">

  [riot-tag=packet-list-view] {
    table.main, table.sub {
      margin: 20px 0;
      align-self: stretch;
      border-spacing: 0px;
      padding: 10px;
      table-layout: fixed;
      width: 100%;
    }

    tr:not(.head):hover {
      background-color: fade(@highlight, 40%);
    }

    tr.selected {
      background-color: @highlight;
    }

    th {
      height: 0;
      opacity: 0;
    }

    td {
      padding: 0 10px;
      cursor: default;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }

  </style>

</packet-list-view>
