<packet-filter-view>
  <input class="compact" type="text" placeholder="Filter" name="filter" onkeypress={apply} oninput={change}>

  <style type="text/less" scoped>
    :scope {
      input {
        border-right-width: 0;
        border-left-width: 0;
        border-bottom-width: 0;
      }
    }
  </style>

  <script type="babel">
    import $ from 'jquery';
    import {
      Session,
      PubSub
    } from 'dripcap';

    this.change = e => {
      try {
        $(this.filter).toggleClass('error', false);
        this.filterText = $(e.target).val().trim();
      } catch (error) {
        $(this.filter).toggleClass('error', true);
        this.filterText = null;
      }
    };

    this.apply = e => {
      if (e.charCode === 13 && (this.filterText != null)) {
        PubSub.pub('packet-filter-view:filter', this.filterText);
      }
      return true;
    };

    Session.on('created', session => {
      PubSub.sub('packet-filter-view:filter', filter => session.setFilter('main', filter));
    });
  </script>
</packet-filter-view>
