<install-preferences-view-item>
<li class="packages border">
  <p class="head">{ opts.pkg.name } ({ opts.pkg.version })<i class="text-label">{ opts.pkg.description }</i>
  </p>
  <ul class="items">
    <li>
      <input type="button" show={ opts.pkg.status === 'none' }      value="Install v{opts.pkg.version}" onclick={ installPackage }>
      <input type="button" show={ opts.pkg.status === 'old' }       value="Update to v{opts.pkg.version}" onclick={ installPackage }>
      <input type="button" show={ opts.pkg.status === 'installed' } value="Up to date" disabled>
      <input type="button" show={ opts.pkg.userPackage && opts.pkg.status !== 'none' } value="Uninstall" onclick={ uninstallPackage }>
      </li>
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
  <install-preferences-view-item each={ pkg in packages } pkg={ pkg }></install-preferences-view-item>
</ul>

<style type="text/less" scoped>
  :scope { padding: 18px; label { margin: 5px 0; display: block; } ul { list-style: none; padding: 0; } li { padding: 6px 0; } }
</style>

<script type="babel">
  import $ from 'jquery';
  import request from 'request';
  import semver from 'semver';
  import url from 'url';
  import {
    Package,
    Action,
    Profile
  } from 'dripcap';

  this.installing = false;
  this.message = '';
  this.remotePackages = [];
  this.packages = [];

  Action.on('core:preferences', () => {
    this.reload();
    this.registry = Profile.getConfig('package-registry');
    Package.resolveRegistry(this.registry).then((host) => {
      request(url.resolve(host, '/list'), (err, res, body) => {
        if (err != null) {
          this.message = "Error: failed to fetch the package lists!";
        } else {
          this.message = '';
          this.remotePackages = JSON.parse(body);
        }
        this.reload();
      });
    });
  });

  this.reload = () => {
    this.packages = [];
    for (let pkg of this.remotePackages) {
      pkg.status = 'none';
      let loaded = Package.list[pkg.name];
      if (loaded != null) {
        pkg.userPackage = loaded.userPackage;
        if (semver.gt(pkg.version, loaded.version)) {
          pkg.status = 'old';
        } else {
          pkg.status = 'installed';
        }
      }
      this.packages.push(pkg);
    }
    this.update();
  };

  Package.sub('core:package-list-updated', this.reload);

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

  this.uninstallPackage = e => {
    let {name} = e.item.pkg;
    let pkg = Package.list[name];
    if (pkg.config.get('enabled')) {
      pkg.deactivate();
    }
    Package.uninstall(pkg.name);
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
    input[type=button][disabled] {
      opacity: 0.5;
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
