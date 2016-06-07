<install-preferences-view-item>
  <li class="packages">
    <p class="head">{ opts.pkg.name } ({ opts.pkg.version })<i>{ opts.pkg.description }</i></p>
    <ul class="items">
      <li>
        <input type="button" value="Install" onclick={ installPackage }>
      </li>
    </ul>
  </li>
</install-preferences-view-item>

<install-preferences-view>

  <ul>
    <li>
      <label>Package Registry: </label> { registry }
    </li>
    <li show={ installing }>
      <i class="fa fa-cog fa-spin"></i> Installing...
    </li>
    <li>
      { message }
    </li>
  </ul>

  <ul>
    <install-preferences-view-item each={ pkg in packageList } pkg={ pkg }>
    </install-preferences-view-item>
  </ul>

  <style type="text/less">
  [riot-tag=install-preferences-view] {
    padding: 18px;

    label {
      margin: 5px 0;
      display: block;
    }

    ul {
      list-style: none;
      padding: 0;
    }

    li {
      padding: 6px 0;
    }
  }
  </style>

  <script type="coffee">
  $ = require('jquery')
  request = require('request')
  url = require('url')

  @installing = false
  @message = ''
  @packageList = []

  dripcap.action.on 'core:preferences', =>
    @registry = dripcap.profile.getConfig('package-registry')
    request url.resolve(@registry, '/api/list'), (err, res, body) =>
      if err?
        @message = "Error: failed to fetch the package lists!"
      else
        @message = ''
        @packageList = JSON.parse body
      @update()

  @installPackage = (e) =>
    name = e.item.pkg.name
    @installing = true
    @message = ''
    dripcap.package.install(name).then =>
      @message = "#{name} has been successfully installed!"
      @installing = false
      @update()
    .catch (e) =>
      @message = e.toString()
      @installing = false
      @update()

  </script>

  <style type="text/less">
  [riot-tag=install-preferences-view] {
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

</install-preferences-view>
