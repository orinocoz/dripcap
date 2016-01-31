<welcome-dialog>

  <modal-dialog>
    <h2>Welcome to Dripcap</h2>
    <p>
      <img src={ parent.logo }>
    </p>
    <p>
      <input type="button" value="Start a New Capturing" onclick={ parent.start }>
    </p>
    <p>
      <input type="button" value="Import a PCAP File" onclick={ parent.pcap }>
    </p>
    <p>
      <input type="button" value="Open Preferences" onclick={ parent.pref }>
    </p>
    <p>
      <input type="button" value="Visit Wiki" onclick={ parent.wiki }>
    </p>
    <p>
      <label>
        <input type="checkbox" name="startup" checked={ parent.startup } onclick={ parent.setStartup }> Show this dialog at startup
      </label>
    </p>
  </modal-dialog>

  <style type="text/less">
  [riot-tag=welcome-dialog] > modal-dialog > .modal > .content {
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

  <script type="coffee">
  $ = require('jquery')

  @on 'mount', =>
    @startup = dripcap.profile.getConfig 'startupDialog'

  @setStartup = (e) =>
    dripcap.profile.setConfig 'startupDialog', $(e.target).is ':checked'

  @show = =>
    @tags['modal-dialog'].show()

  @hide = =>
    @tags['modal-dialog'].hide()

  @start = =>
    dripcap.action.emit 'core:new-session'

  @pcap = =>
    @tags['modal-dialog'].hide()
    dripcap.action.emit 'pcap-file:open'

  @pref = =>
    dripcap.action.emit 'core:preferences'

  @wiki = =>
    dripcap.action.emit 'core:open-wiki'

  </script>

</welcome-dialog>
