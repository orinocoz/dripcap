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

  </script>

</preferences-dialog>
