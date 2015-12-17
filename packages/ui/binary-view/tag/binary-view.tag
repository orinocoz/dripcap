<binary-view>

  <div class="container">
    <div class="hex"></div>
    <div class="ascii"></div>
  </div>

  <script type="coffee">

  </script>

  <style type="text/less">
    [riot-tag=binary-view] {
      .container {
        display: flex;
        justify-content: center;
        width: 100%;
      }

      .hex, .ascii {
          list-style: none;
          font-family: monospace;
          padding: 10px;
          -webkit-user-select: text;
      }

      i {
        display: inline-block;
          font-style: normal;
          width: 23px;
      }

      i.selected {
        background-color: @highlight;
      }
    }
  </style>

</binary-view>
