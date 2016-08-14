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

  this.change = e => {
    try {
      $(this.filter).toggleClass('error', false);
      return this.filterText = $(e.target).val().trim();
    } catch (error) {
      $(this.filter).toggleClass('error', true);
      return this.filterText = null;
    }
  };

  this.apply = e => {
    if (e.charCode === 13 && (this.filterText != null)) {
      dripcap.pubsub.pub('packet-filter-view:filter', this.filterText);
    }
    return true;
  };

  dripcap.session.on('created', session => {
    return dripcap.pubsub.sub('packet-filter-view:filter', filter => session.setFilter('main', filter)
    );
  }
  );
  </script>
</packet-filter-view>
