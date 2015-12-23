<install-preferences-view>

  <ul>
    <li>
      <label>Package Registry: </label> { dripcap.profile.getConfig('package-registory') }
    </li>
    <li>
      <label for="name">Package Name</label>
      <input type="text" name="name" placeholder="" oninput={ changeName }>
    </li>
    <li>
      <input type="button" name="install" value="Install" onclick={ installPackage }>
    </li>
    <li show={ installing }>
      <i class="fa fa-cog fa-spin"></i> Installing...
    </li>
    <li>
      { message }
    </li>
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

  @installing = false
  @message = ''

  @changeName = =>
    $(@install).prop 'disabled', $(@name).val().length == 0

  @installPackage = =>
    name = $(@name).val()
    $(@name).val('')
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

</install-preferences-view>
