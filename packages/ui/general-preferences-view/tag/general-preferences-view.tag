<general-preferences-view>

  <ul>
    <li>
      <label for="theme">Theme</label>
      <select name="theme" onchange={ updateTheme }>
        <option each={ id, theme in themeList } value={ id } selected={ id == currentTheme }>{ theme.name }</option>
      </select>
    </li>
  </ul>

  <style type="text/less">
  [riot-tag=general-preferences-view] {
    padding: 18px;

    label {
      margin: 5px 0;
      display: block;
    }

    ul {
      list-style: none;
      padding: 0;
    }
  }
  </style>

  <script type="es6">

  this.setThemeList = (list) => {
    this.currentTheme = dripcap.theme.id
    this.themeList = list
  }

  this.updateTheme = () => {
    dripcap.theme.id = $(this.theme).val()
  }

  </script>

</general-preferences-view>
