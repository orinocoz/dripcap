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
        <li if={ pkg.userPackage }>
          <input type="button" value="Uninstall" onclick={ uninstallPackage }>
        </li>
      </ul>
    </li>
  </ul>

  <script type="coffee">
    _ = require('underscore')

    @setEnabled = (e) =>
      pkg = e.item.pkg
      enabled = $(e.currentTarget).is(':checked')
      pkg.config.enabled = enabled
      dripcap.profile.setPackage pkg.name, pkg.config
      if enabled
        pkg.activate()
      else
        pkg.deactivate()

    @uninstallPackage = (e) =>
      pkg = e.item.pkg
      pkg.deactivate() if pkg.config.enabled
      dripcap.package.uninstall(pkg.name).then =>
        $(e.target).parents('li.packages').fadeOut 400, =>
          @packageList = _.without(@packageList, pkg)
          @update()

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
        display: inline;

        input {
          max-width: 120px;
          margin: 0 10px;
        }
      }
    }

    ul {
      list-style: none;
      padding: 0;
    }
  }
  </style>

</package-preferences-view>
