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

          @packets = 0
          @prevStart = -1
          @prevEnd = -1
          @selectedId = -1
          @filter = ''

          @view = $('[riot-tag=packet-list-view]')
          @view.scroll _.debounce((=> @update()), 500)

          dripcap.session.on 'created', (session) =>
            session.on 'packet', (pkt) =>
              if pkt.id == @selectedId
                dripcap.pubsub.pub 'packet-list-view:select', pkt
              process.nextTick =>
                @cells.filter("[data-packet=#{pkt.id}]:visible").text("#{pkt.name} #{pkt.len}")
            @session = session

          @main = $('[riot-tag=packet-list-view] div.main')
          for i in [0..100]
            @main.append($('<div class="packet">'))
          @cells = @main.children('div.packet')
          @cells.hide()

          self = @
          @cells.click ->
            $(this).siblings('.selected').removeClass('selected')
            $(this).addClass('selected')
            self.selectedId = parseInt $(this).attr('data-packet')
            process.nextTick -> self.session.requestPackets([self.selectedId])

          canvas = $("<canvas width='64' height='64'>")[0]
          ctx = canvas.getContext("2d")
          ctx.fillStyle = 'rgba(255, 255, 255, 0.05)'
          ctx.fillRect(0, 0, 64, 32)
          @main.css('background-image', "url(#{canvas.toDataURL('image/png')})")

          dripcap.pubsub.sub 'core:captured-packets', (n) =>
            @packets = n
            @update()

          dripcap.pubsub.sub 'core:filtered-packets', (n) =>
            @filtered = n.main
            @update()

          dripcap.pubsub.sub 'packet-filter-view:filter', (filter) =>
            @filter = filter
            @session.setFilter 'main', filter
            @main.children('div.packet').hide()
            @prevStart = -1
            @prevEnd = -1
            @update()

  update: () ->
    if @filter == ''
      @main.css('height', (32 * @packets) + 'px')
    else
      @main.css('height', (32 * @filtered) + 'px')

    start = Math.max(1, Math.floor(@view.scrollTop() / 32 - 20))
    end = Math.min(@packets, Math.floor((@view.scrollTop() + @view.height()) / 32 + 20))

    @main.children('div.packet:visible').each (i, ele) =>
      pos = parseInt($(ele).css('top'))
      margin = 32 * 20
      if pos + $(ele).height() + margin < @view.scrollTop() || pos - margin > @view.scrollTop() + @view.height()
        $(ele).hide()

    if @prevStart != start || @prevEnd != end
      @prevStart = start
      @prevEnd = end
      if @session? && start <= end
        packets = []
        if @filter == ''
          for i in [start..end]
            unless @cells.is("[data-packet=#{i}]:visible")
              packets.push(i)
          @main.children('div.packet:not(:visible)').each (i, ele) =>
            return if (i >= packets.length)
            id = packets[i]
            $(ele).attr('data-packet', id).toggleClass('selected', @selectedId == id).text('').css('top', (32 * (id - 1)) + 'px').show()

          @session.requestPackets(packets)
        else
          @session.getFiltered('main', start, end).then (list) =>
            packets = list
            @main.children('div.packet:not(:visible)').each (i, ele) =>
              return if (i >= packets.length)
              id = packets[i]
              $(ele).attr('data-packet', id).toggleClass('selected', @selectedId == id).text('').css('top', (32 * (start + i - 1)) + 'px').show()

            @session.requestPackets(packets)


  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.left('packet-list-view')
      @list.unmount()
      @comp.destroy()

module.exports = PacketListView
