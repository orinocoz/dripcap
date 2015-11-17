<package-preferences-view>

  <ul>
    <li each={ pkg in packageList } class="packages">
      <p class="head">{ pkg.name } <i>{ pkg.description }</i></p>
      <ul class="items">
        <li>
          <label>
            <input type="checkbox" name="enabled" onclick={ setEnabled } checked={ pkg.config.enabled }> Enabled
          </label>
        </li>
      </ul>
    </li>
  </ul>

  <script type="text/coffeescript">

    @setEnabled = (e) =>
      pkg = e.item.pkg
      enabled = $(e.currentTarget).is(':checked')
      pkg.config.enabled = enabled
      dripcap.profile.setPackage pkg.name, pkg.config
      if enabled
        pkg.activate()
      else
        pkg.deactivate()

  </script>

  <style type="text/less">
  [riot-tag=package-preferences-view] {
    padding: 18px;
    overflow-y: scroll;

    li.packages {
      padding: 15px;
      margin: 15px auto;
      border: 1px solid @border;
      border-radius: 5px;

      p.head {
        margin: 0;
        i {
          color: @label;
          float: right;
          width: 50%;
          text-align: right;
          overflow: hidden;
          white-space: nowrap;
          text-overflow: ellipsis;
        }
      }
    }

    ul.items {
      padding: 10px 0 0 0;
      li {
        padding: 5px 0;
      }
    }

    ul {
      list-style: none;
      padding: 0;
    }
  }
  </style>

</package-preferences-view>
