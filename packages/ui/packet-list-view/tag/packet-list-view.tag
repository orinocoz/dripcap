<packet-list-view>

  <div class="main"></div>

  <style type="text/less" scoped>
    :scope {
      div.main {
        align-self: stretch;
        border-spacing: 0;
        table-layout: fixed;
        width: 100%;
        div.packet {
          width: 100%;
          height: 32px;
          position: absolute;
          display: flex;
          align-items: center;
          a {
            text-decoration: none;
            flex-grow: 1;
            padding-left: 15px;
            cursor: default;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            width: 0;
          }
          a:nth-child(2),
          a:nth-child(4) {
            flex-grow: 4;
          }
          a:nth-child(3) {
            flex-grow: 0.5;
            text-align: center;
          }
        }
      }
    }
  </style>
</packet-list-view>
