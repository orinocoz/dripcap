<modal-dialog>

  <div class="modal" show={ visible } onclick={ cancel }>
    <div class="content border" tabindex="0">
      <yield/>
    </div>
  </div>

  <style type="text/less" scoped>
  :scope {
    .modal {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: center;
      position: absolute;
      top: 0; right: 0; bottom: 0; left: 0;

      .content {
        width: 80%;
        max-width: 1200px;
        padding: 10px 20px;
        border-top: 0px;
        border-radius: 0px 0px 5px 5px;
        align-self: flex-start;
      }
    }
  }

  </style>

  <script type="babel">
  import $ from 'jquery';

  this.visible = false;

  this.show = () => {
    let prev = this.constructor.currentDialog;
    if (prev) {
      prev.hide();
      prev.update();
    }
    this.constructor.currentDialog = this;
    this.visible = true;
    return process.nextTick(() => $('.content').focus());
  };

  this.hide = () => {
    this.visible = false;
    return this.constructor.currentDialog = null;
  };

  this.cancel = e => {
    if (e.currentTarget === e.target) {
      this.hide();
    }
    return true;
  };
  </script>

</modal-dialog>
