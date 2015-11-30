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

  <style type="text/less">
  [riot-tag=session-dialog] > modal-dialog > .modal > .content {
    max-width: 600px;
  }
  </style>

  <script type="es6">

  this.setInterfaceList = (list) => this.interfaceList = list

  this.show = () => this.tags['modal-dialog'].show()

  this.start  = () => {
    let ifs = $(this.tags['modal-dialog'].interface).val()
    let filter = $(this.tags['modal-dialog'].filter).val()
    let promisc = $(this.tags['modal-dialog'].promisc).prop('checked')

    this.tags['modal-dialog'].hide()
    let sess = dripcap.session.create(ifs, {filter: filter, promisc: promisc})
    dripcap.session.list = [sess]
    dripcap.session.emit('created', sess)
    sess.start()
  }

  </script>

</session-dialog>
