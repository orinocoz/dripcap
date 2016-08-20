<preferences-dialog>

  <modal-dialog></modal-dialog>

  <style type="text/less" scoped>
    :scope > modal-dialog > .modal > .content {
      height: 70%;
      position: relative;
    }
  </style>

  <script type="babel">
    this.setInterfaceList = list => {
      this.interfaceList = list;
    };

    this.show = () => {
      this.tags['modal-dialog'].show();
    };
  </script>

</preferences-dialog>
