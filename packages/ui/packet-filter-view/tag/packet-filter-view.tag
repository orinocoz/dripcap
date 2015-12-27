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

  <script type="coffee">
    $ = require('jquery')
    parse = require('dripper/filter-parse')

    @change = (e) =>
      try
        filter = $(e.target).val().trim()
        $(@filter).toggleClass('error', false)
        parse(filter)
        dripcap.pubsub.pub 'packet-filter-view:filter', filter
      catch error
        $(@filter).toggleClass('error', true)

  </script>
</packet-filter-view>
