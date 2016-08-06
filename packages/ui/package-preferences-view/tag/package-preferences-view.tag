<package-preferences-view-item>
  <li class="packages">
    <p class="head">{ opts.pkg.name } <i>{ opts.pkg.description }</i></p>
    <ul class="items">
      <li>
        <label>
          <input type="checkbox" name="enabled" onclick={ setEnabled } checked={ opts.pkg.config.get('enabled') }> Enabled
        </label>
      </li>
      <li>
        <div class="preferences"></div>
      </li>
      <li if={ opts.pkg.userPackage }>
        <input type="button" value="Uninstall" onclick={ uninstallPackage }>
      </li>
    </ul>
  </li>

  <script type="coffee">
    $ = require('jquery')

    @on 'mount', =>
      @pref = $(@root).find('.preferences').empty()
      if elem = opts.pkg.renderPreferences()
        @pref.append elem
    </script>
</package-preferences-view-item>

<package-preferences-view>
  <ul>
    <package-preferences-view-item each={ pkg in packageList } pkg={ pkg }>
    </package-preferences-view-item>
  </ul>

  <script type="coffee">
    _ = require('underscore')
    $ = require('jquery')

    @setEnabled = (e) =>
      pkg = e.item.pkg
      enabled = $(e.currentTarget).is(':checked')
      pkg.config.set 'enabled', enabled
      if enabled
        pkg.activate()
      else
        pkg.deactivate()

    @uninstallPackage = (e) =>
      pkg = e.item.pkg
      pkg.deactivate() if pkg.config.get 'enabled'
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
      border: 1px solid var(--dripcap-theme-border);
      border-radius: 5px;

      p.head {
        margin: 0;
        i {
          color: var(--dripcap-theme-label);
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

      .preferences {
        margin: 20px 10px 10px;
      }
    }

    ul {
      list-style: none;
      padding: 0;
    }
  }
  </style>

</package-preferences-view>
