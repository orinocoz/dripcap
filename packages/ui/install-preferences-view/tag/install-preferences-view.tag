<install-preferences-view-item>
<li class="packages border">
  <p class="head">{ opts.pkg.name } ({ opts.pkg.version })<i class="text-label">{ opts.pkg.description }</i>
  </p>
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
    <label>Package Registry:
    </label>
    { registry }
  </li>
  <li show={ installing }>
    <i class="fa fa-cog fa-spin"></i>
    Installing...
  </li>
  <li>
    { message }
  </li>
</ul>

<ul>
  <install-preferences-view-item each={ pkg in packageList } pkg={ pkg }></install-preferences-view-item>
</ul>

<style type="text/less" scoped>
  :scope { padding: 18px; label { margin: 5px 0; display: block; } ul { list-style: none; padding: 0; } li { padding: 6px 0; } }
</style>

<script type="babel">
  import $ from 'jquery';
  import request from 'request';
  import url from 'url';
  import {
    Package,
    Action,
    Profile
  } from 'dripcap';

  this.installing = false;
  this.message = '';
  this.packageList = [];

  Action.on('core:preferences', () => {
    this.registry = Profile.getConfig('package-registry');
    Package.resolveRegistry(this.registry).then((host) => {
      request(url.resolve(host, '/list'), (err, res, body) => {
        if (err != null) {
          this.message = "Error: failed to fetch the package lists!";
        } else {
          this.message = '';
          this.packageList = JSON.parse(body);
        }
        this.update();
      });
    });
  });

  this.installPackage = e => {
    let {name} = e.item.pkg;
    this.installing = true;
    this.message = '';
    return Package.install(name).then(() => {
      this.message = `${name} has been successfully installed!`;
      this.installing = false;
      this.update();
    }).catch(e => {
      this.message = e.toString();
      this.installing = false;
      this.update();
    });
  };
</script>

<style type="text/less" scoped>
  :scope {
    padding: 18px;
    overflow-y: scroll;
    li.packages {
      padding: 15px;
      margin: 15px auto;
      border-radius: 5px;
      p.head {
        margin: 0;
        i {
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
      padding: 10px 0 0;
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
