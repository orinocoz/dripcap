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

  <script type="text/coffeescript">

  @setThemeList = (list) =>
    @currentTheme = dripcap.theme.id
    @themeList = list

  @updateTheme = =>
    dripcap.theme.id = $(@theme).val()

  </script>

</general-preferences-view>
