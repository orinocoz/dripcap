<status-view>
  <div class="status">
    <span class={ button: 1, disabled: capturing } onclick={ startCapture }><a href="#"><i class="fa fa-play"></i></a></span>
    <span class={ button: 1, disabled: !capturing } onclick={ stopCapture }><a href="#"><i class="fa fa-pause"></i></a></span>
    <span class="button" onclick={ newCapture }><a href="#"><i class="fa fa-file-o"></i></a></span>
    <span show={ capturing }><i class="fa fa-cog fa-spin"></i> capturing</span>
    <span show={ !capturing }><i class="fa fa-cog"></i> paused</span>
    <span if={ settings }><i class="fa fa-crosshairs"></i> { settings.iface }</span>
    <span if={ settings } show={ settings.options.filter }><i class="fa fa-filter"></i> { settings.options.filter }</span>
    <span if={ settings } show={ settings.options.promisc }><i class="fa fa-eye"></i> promiscuous</span>
  </div>

  <style type="text/less">
    @splitter: fade(@scroll-bar, 40%);

    [riot-tag=status-view] {
      border-bottom: 1px solid @splitter;
      -webkit-app-region: drag;

      .status {
        width: 100%;
        padding: 10px;
        color: @label;
        cursor: default;
      }

      span {
        padding: 6px 10px;
        -webkit-app-region: no-drag;
      }

      .disabled {
        opacity: 0.5;
      }

      span.button {
        color: @headline;
        cursor: pointer;
      }
    }
  </style>

  <script type="babel">
  import $ from 'jquery';

  this.on('mount', () => {
    if (process.platform === 'darwin') {
      return $(this.root).css('padding-left', '90px');
    }
  }
  );

  this.startCapture = () => {
    return dripcap.action.emit('core:start-sessions');
  };

  this.stopCapture = () => {
    return dripcap.action.emit('core:stop-sessions');
  };

  this.newCapture = () => {
    return dripcap.action.emit('core:new-session');
  };
  </script>

</status-view>
