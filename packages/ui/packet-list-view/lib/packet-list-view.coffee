$ = require('jquery')
_ = require('underscore')
riot = require('riot')
fs = require('fs')
Component = require('dripcap/component')
remote = require('electron').remote
Menu = remote.Menu
MenuItem = remote.MenuItem
dialog = remote.dialog

class PacketListView
  activate: ->
    new Promise (res) =>
      @comp = new Component "#{__dirname}/../tag/*.tag"
      dripcap.package.load('main-view').then (pkg) =>
        $ =>
          m = $('<div class="wrapper noscroll" />')
          pkg.root.panel.left('packet-list-view', m)

          n = $('<div class="wrapper" />').attr('tabIndex', '0').appendTo m
          @list = riot.mount(n[0], 'packet-list-view', items: [])[0]

          @view = $('[riot-tag=packet-list-view]')
          @view.scroll _.debounce((=> @update()), 100)

          dripcap.pubsub.sub 'packet-filter-view:filter', (filter) =>
            @filtered = 0
            @reset()
            @update()

          dripcap.session.on 'created', (session) =>
            @session = session
            @packets = 0
            @filtered = -1
            @reset()
            @update()

            session.on 'status', (n) =>
              @packets = n.packets

              if n.filtered.main?
                @filtered = n.filtered.main
              else
                @filtered = -1

              @update()

            session.on 'packet', (pkt) =>
              if pkt.id == @selectedId
                dripcap.pubsub.pub 'packet-list-view:select', pkt
              process.nextTick =>
                @cells.filter("[data-packet=#{pkt.id}]:visible")
                  .empty()
                  .append($('<a>').text(pkt.name))
                  .append($('<a>').text(pkt.attrs.src))
                  .append($('<a>').append($('<i class="fa fa-angle-double-right">')))
                  .append($('<a>').text(pkt.attrs.dst))
                  .append($('<a>').text(pkt.len))

          @main = $('[riot-tag=packet-list-view] div.main')

          canvas = $("<canvas width='64' height='64'>")[0]
          ctx = canvas.getContext("2d")
          ctx.fillStyle = 'rgba(255, 255, 255, 0.05)'
          ctx.fillRect(0, 0, 64, 32)
          @main.css('background-image', "url(#{canvas.toDataURL('image/png')})")

          @reset()

  reset: ->
    @prevStart = -1
    @prevEnd = -1
    @selectedId = -1
    @main.empty()
    @cells = $([])

  update: ->
    margin = 5
    height = 32

    num = @packets
    if @filtered != -1
      num = @filtered

    @main.css('height', (height * num) + 'px')
    start = Math.max(1, Math.floor(@view.scrollTop() / height - margin))
    end = Math.min(num, Math.floor((@view.scrollTop() + @view.height()) / height + margin))

    @cells.filter(':visible').each (i, ele) =>
      pos = parseInt($(ele).css('top'))
      if pos + $(ele).height() + (margin * height) < @view.scrollTop() || pos - (margin * height) > @view.scrollTop() + @view.height()
        $(ele).hide()

    if @prevStart != start || @prevEnd != end
      @prevStart = start
      @prevEnd = end
      if @session? && start <= end
        if @filtered == -1
          list = []
          for i in [start..end]
            list.push i
          @updateCells start - 1, list
        else
          @session.getFiltered('main', start, end).then (list) =>
            @updateCells start - 1, list

  updateCells: (start, list) ->
    packets = []
    indices = []
    for id, n in list
      unless @cells.is("[data-packet=#{id}]:visible")
        packets.push(id)
        indices.push(start + n)

    needed = packets.length - @cells.filter(':not(:visible)').length
    if needed > 0
      for i in [1..(needed)]
        self = @
        $('<div class="packet">').appendTo(@main).hide().click ->
          $(this).siblings('.selected').removeClass('selected')
          $(this).addClass('selected')
          self.selectedId = parseInt $(this).attr('data-packet')
          process.nextTick -> self.session.requestPackets([self.selectedId])

      @cells = @main.children('div.packet')

    @cells.filter(':not(:visible)').each (i, ele) =>
      return if (i >= packets.length)
      id = packets[i]
      $(ele).attr('data-packet', id).toggleClass('selected', @selectedId == id).empty().css('top', (32 * indices[i]) + 'px').show()

    @session.requestPackets(packets)

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.left('packet-list-view')
      @list.unmount()
      @comp.destroy()

module.exports = PacketListView
