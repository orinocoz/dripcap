<packet-filter-view>
  <input class="compact" type="text" placeholder="Filter" name="filter" oninput={change}>

  <style type="text/less">
    [riot-tag=packet-filter-view] {
      input {
        border-right-width: 0;
        border-left-width: 0;
        border-bottom-width: 0;
      }
    }
  </style>

  <script type="es6">
    import parse from 'dripper/filter-parse'

    this.change = (e) => {
      try {
        let filter = $(e.target).val().trim()
        $(this.filter).toggleClass('error', false)
        parse(filter)
        dripcap.pubsub.pub('PacketFilterView:filter', filter)
      } catch (error) {
        $(this.filter).toggleClass('error', true)
      }
    }
  </script>
</packet-filter-view>
