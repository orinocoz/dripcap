<welcome-dialog>

  <modal-dialog>
    <h2>Welcome to Dripcap</h2>
    <p>
      <img src={ parent.logo }>
    </p>
    <p>
      <input type="button" value="Start New Capturing" onclick={ parent.start }>
    </p>
    <p>
      <input type="button" value="Import PCAP File" onclick={ parent.pcap }>
    </p>
    <p>
      <input type="button" value="Open Preferences" onclick={ parent.pref }>
    </p>
    <p>
      <input type="button" value="Visit Wiki" onclick={ parent.wiki }>
    </p>
    <p>
      <label>
        <input type="checkbox" name="startup" checked={ parent.startup } onclick={ parent.setStartup }>
        Show this dialog at startup
      </label>
    </p>
  </modal-dialog>

  <style type="text/less" scoped>
    :scope > modal-dialog > .modal > .content {
      max-width: 600px;
      input[type=button] {
        height: 50px;
      }
      img {
        width: 64px;
        height: 64px;
        margin: 0 auto;
        display: block;
      }
    }
  </style>

  <script type="babel">
    import $ from 'jquery';
    import { Action, Profile } from 'dripcap';

    this.on('mount', () => {
      return this.startup = Profile.getConfig('startupDialog');
    });

    this.setStartup = e => {
      return Profile.setConfig('startupDialog', $(e.target).is(':checked'));
    };

    this.show = () => {
      return this.tags['modal-dialog'].show();
    };

    this.hide = () => {
      return this.tags['modal-dialog'].hide();
    };

    this.start = () => {
      return Action.emit('core:new-session');
    };

    this.pcap = () => {
      this.tags['modal-dialog'].hide();
      return Action.emit('pcap-file:open');
    };

    this.pref = () => {
      return Action.emit('core:preferences');
    };

    this.wiki = () => {
      return Action.emit('core:open-wiki');
    };
  </script>

</welcome-dialog>
