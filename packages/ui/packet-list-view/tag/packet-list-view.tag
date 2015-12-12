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

  <script type="es6">

  this.on('mount', () => {
    let hover = $(this.root).find('.hover-slider')
    hover.on('mouseup mouseout', () => $(this).hide())
    $(this.root).find('.slider').on('mousedown', () => hover.data('slider', $(this)).show())

    let root = $(this.root)
    self = this
    hover.on('mousemove', (e) => {
      let slider = $(this).data('slider')
      let prev = slider.prevAll('.container').first()
      let next = slider.nextAll('.container').first()

      let left = prev.position().left
      let right = left + prev.width() + next.width()
      let ratio = (e.clientX - left) / (right - left)
      let sum = parseFloat(prev.css('flex-grow')) + parseFloat(next.css('flex-grow'))
      prev.css('flex-grow', ratio * sum)
      next.css('flex-grow', (1.0 - ratio) * sum)
      self.calculate()
    })

    let width = [0.6, 1.3, 1.3, 0.6]
    $(this.root).children('.container').each((i, elem) => $(elem).css('flex-grow', width[i]))
    this.calculate()
  })

  this.calculate = () => {
    let con = $(this.root).children('.container')
    let sum = 0
    con.each(() => sum += $(this).width())
    let thMain = $('[riot-tag=packet-list-view] table.main th')
    let thSub = $('[riot-tag=packet-list-view] table.sub th')
    con.each((i) => {
      $(thMain[i]).css('width', ($(this).width() / sum * 100) + '%')
      $(thSub[i]).css('width', ($(this).width() / sum * 100) + '%')
    })
  }

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
