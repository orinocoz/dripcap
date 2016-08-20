<status-view class="border">
  <div class="status text-label">
    <span class={ button: 1, text-headline: 1, disabled: capturing } onclick={ startCapture }>
      <a href="#">
        <i class="fa fa-play"></i>
      </a>
    </span>
    <span class={ button: 1, text-headline: 1, disabled: !capturing } onclick={ stopCapture }>
      <a href="#">
        <i class="fa fa-pause"></i>
      </a>
    </span>
    <span class="button text-headline" onclick={ newCapture }>
      <a href="#">
        <i class="fa fa-file-o"></i>
      </a>
    </span>
    <span show={ capturing }>
      <i class="fa fa-cog fa-spin"></i>
      capturing</span>
    <span show={ !capturing }>
      <i class="fa fa-cog"></i>
      paused</span>
    <span if={ settings }>
      <i class="fa fa-crosshairs"></i>
      { settings.iface }</span>
    <span if={ settings } show={ settings.options.filter }>
      <i class="fa fa-filter"></i>
      { settings.options.filter }</span>
    <span if={ settings } show={ settings.options.promiscuous }>
      <i class="fa fa-eye"></i>
      promiscuous</span>
  </div>

  <style type="text/less" scoped>
    :scope.border {
      border-width: 0 0 1px 0;
      -webkit-app-region: drag;
      .status {
        width: 100%;
        padding: 10px;
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
        cursor: pointer;
      }
    }
  </style>

  <script type="babel">
    import $ from 'jquery';
    import {Action} from 'dripcap';

    this.on('mount', () => {
      if (process.platform === 'darwin') {
        $(this.root).css('padding-left', '90px');
      }
    });

    this.startCapture = () => {
      Action.emit('core:start-sessions');
    };

    this.stopCapture = () => {
      Action.emit('core:stop-sessions');
    };

    this.newCapture = () => {
      Action.emit('core:new-session');
    };
  </script>

</status-view>
