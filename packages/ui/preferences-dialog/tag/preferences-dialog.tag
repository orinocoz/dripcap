<preferences-dialog>

  <modal-dialog></modal-dialog>

  <style type="text/less">
  [riot-tag=preferences-dialog] > modal-dialog > .modal > .content {
    height: 70%;
    position: relative;
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

    @tags['modal-dialog'].hide()
    sess = dripcap.session.create ifs, filter: filter, promisc: promisc
    dripcap.session.list = [sess]
    dripcap.session.emit('created', sess)
    sess.start()

  </script>

</preferences-dialog>
