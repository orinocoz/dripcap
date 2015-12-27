<modal-dialog>

  <div class="modal" show={ visible } onclick={ cancel }>
    <div class="content" tabindex="0">
      <yield/>
    </div>
  </div>

  <style type="text/less">
  modal-dialog {
    & > .modal {
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: center;
      position: absolute;
      top: 0; right: 0; bottom: 0; left: 0;
      background-color: fade(@background, 70%);

      & > .content {
        width: 80%;
        max-width: 1200px;
        padding: 10px 20px;
        border: 1px solid @border;
        border-top: 0px;
        border-radius: 0px 0px 5px 5px;
        background-color: @background;
        align-self: flex-start;
      }
    }
  }

  </style>

  <script type="coffee">
  $ = require('jquery')
  
  @visible = false

  @show = =>
    prev = @constructor.currentDialog
    if prev
      prev.hide()
      prev.update()
    @constructor.currentDialog = @
    @visible = true
    process.nextTick -> $('.content').focus()

  @hide = =>
    @visible = false
    @constructor.currentDialog = null

  @cancel = (e) =>
    if e.currentTarget == e.target
      @hide()
    true

  </script>

</modal-dialog>
