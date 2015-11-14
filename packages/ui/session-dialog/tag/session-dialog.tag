<session-dialog>

  <modal-dialog>
    <h2>New session</h2>
    <p>
      <select name="interface">
        <option each={ parent.interfaceList } value={ name }>{ name }</option>
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

  <script type="text/coffeescript">

  @setInterfaceList = (list) =>
    @interfaceList = list

  @show = =>
    @tags['modal-dialog'].show()

  @start = =>
    ifs = $(@tags['modal-dialog'].interface).val()
    filter = $(@tags['modal-dialog'].filter).val()
    promisc = $(@tags['modal-dialog'].promisc).prop('checked')

    @tags['modal-dialog'].hide()
    sess = dripcap.session.create ifs, filter: filter, promisc: promisc
    dripcap.session.list = [sess]
    dripcap.session.emit('created', sess)
    sess.start()

  </script>

</session-dialog>
