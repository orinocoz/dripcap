<preferences-dialog>

  <modal-dialog></modal-dialog>

  <style type="text/less">
  [riot-tag=preferences-dialog] > modal-dialog > .modal > .content {
    height: 70%;
    position: relative;
  }
  </style>

  <script type="es6">

  this.setInterfaceList = (list) => {
    this.interfaceList = list
  }

  this.show = () => this.tags['modal-dialog'].show()

  this.start = (list) => {
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

</preferences-dialog>
