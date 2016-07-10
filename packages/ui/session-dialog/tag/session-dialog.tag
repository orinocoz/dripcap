<session-dialog>

  <modal-dialog>
    <h2>New session</h2>
    <p>
      <select name="interface">
        <option each={ parent.interfaceList } if={ link === 1 } value={ name }>{ name }</option>
      </select>
    </p>
    <p>
      <input type="text" name="filter" placeholder="filter (BPF)">
    </p>
    <p>
      <label>
        <input type="checkbox" name="promisc"> Promiscuous mode
      </label>
    </p>
    <p>
      <input type="button" name="start" value="Start" onclick={ parent.start }>
    </p>
  </modal-dialog>

  <style type="text/less">
  [riot-tag=session-dialog] > modal-dialog > .modal > .content {
    max-width: 600px;
  }
  </style>

  <script type="coffee">
  $ = require('jquery')

  @setInterfaceList = (list) =>
    @interfaceList = list

  @show = =>
    @tags['modal-dialog'].show()

  @start = =>
    ifs = $(@tags['modal-dialog'].interface).val()
    filter = $(@tags['modal-dialog'].filter).val()
    promisc = $(@tags['modal-dialog'].promisc).prop('checked')
    snaplen = dripcap.profile.getConfig 'snaplen'

    @tags['modal-dialog'].hide()
    dripcap.session.create(ifs, filter: filter, promisc: promisc).then (sess) =>
      dripcap.session.list = [sess]
      dripcap.session.emit('created', sess)
      sess.start()

  </script>

</session-dialog>
