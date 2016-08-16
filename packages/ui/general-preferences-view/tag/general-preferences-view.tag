<general-preferences-view>

  <ul>
    <li>
      <label for="theme">Theme</label>
      <select name="theme" onchange={ updateTheme }>
        <option each={ id, theme in themeList } value={ id } selected={ id==currentTheme }>{ theme.name }</option>
      </select>
    </li>
    <li>
      <label for="snaplen">Snapshot Length (bytes)</label>
      <input type="number" name="snaplen" placeholder="1600" onchange={ updateSnaplen } value={ currentSnaplen }>
    </li>
  </ul>

  <style type="text/less" scoped>
    :scope {
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

  <script type="babel">
    import $ from 'jquery';
    import { Theme, Profile } from 'dripcap';

    this.on('mount', () => {
      this.currentSnaplen = Profile.getConfig('snaplen');
    });

    this.setThemeList = (list) => {
      this.currentTheme = Theme.id;
      this.themeList = list;
    };

    this.updateTheme = () => {
      Theme.id = $(this.theme).val();
    };

    this.updateSnaplen = () => {
      let len = parseInt($(this.snaplen).val());
      Profile.setConfig('snaplen', len);
    };
  </script>

</general-preferences-view>
