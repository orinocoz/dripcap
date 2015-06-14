<status-view>
  <div class="status">
    <span class="capturing" show={ capturing } onclick={ stopCapture }><i class="fa fa-cog fa-spin"></i> <a href="#">capturing</a></span>
    <span show={ !capturing } onclick={ startCapture }><i class="fa fa-cog"></i> <a href="#">paused</a></span>
    <span if={ settings }><i class="fa fa-crosshairs"></i> { settings.iface }</span>
    <span if={ settings } show={ settings.options.filter }><i class="fa fa-filter"></i> { settings.options.filter }</span>
    <span if={ settings } show={ settings.options.promisc }><i class="fa fa-eye"></i> promiscuous</span>
  </div>

  <style type="text/less">
    @splitter: fade(@scroll-bar, 40%);

    [riot-tag=status-view] {
      border-bottom: 1px solid @splitter;

      .status {
        width: 100%;
        padding: 12px 10px;
        color: @label;
        cursor: default;
      }

      span {
        padding: 6px 10px;
      }

      .capturing {
        color: @headline;
      }
    }
  </style>

  <script type="text/coffeescript">

  @on 'mount', =>
    if process.platform == 'darwin'
      $(@root).css 'padding-left', '90px'

  @startCapture = ->
    dripcap.action.emit 'Core: Start Sessions'

  @stopCapture = ->
    dripcap.action.emit 'Core: Stop Sessions'

  </script>

</status-view>
