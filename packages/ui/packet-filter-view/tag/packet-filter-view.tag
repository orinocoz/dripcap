<packet-filter-view>
  <input class="compact" type="text" placeholder="Filter" name="filter" onkeypress={apply} oninput={change}>

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

    @change = (e) =>
      try
        $(@filter).toggleClass('error', false)
        @filterText = $(e.target).val().trim()
      catch error
        $(@filter).toggleClass('error', true)
        @filterText = null

    @apply = (e) =>
      if e.charCode == 13 && @filterText?
        dripcap.pubsub.pub 'packet-filter-view:filter', @filterText
      true

  </script>
</packet-filter-view>
