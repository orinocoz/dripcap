<preferences-dialog>

  <modal-dialog></modal-dialog>

  <style type="text/less">
  [riot-tag=preferences-dialog] > modal-dialog > .modal > .content {
    height: 70%;
    position: relative;
  }
  </style>

  <script type="babel">
  import $ from 'jquery';

  this.setInterfaceList = list => {
    return this.interfaceList = list;
  };

  this.show = () => {
    return this.tags['modal-dialog'].show();
  };
  </script>

</preferences-dialog>
