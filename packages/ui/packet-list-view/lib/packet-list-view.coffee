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

          dripcap.session.on 'created', (session) =>
            session.on 'packet', (pkt) =>
              if pkt.id == @selectedId
                dripcap.pubsub.pub 'packet-list-view:select', pkt
              process.nextTick =>
                @cells.filter("[data-packet=#{pkt.id}]:visible").text("#{pkt.name} #{pkt.len}")
            @packets = 0
            @prevStart = -1
            @prevEnd = -1
            @selectedId = -1
            @session = session
            @cells.remove()
            @cells = $([])
            @update()

          @main = $('[riot-tag=packet-list-view] div.main')
          @cells = $([])

          canvas = $("<canvas width='64' height='64'>")[0]
          ctx = canvas.getContext("2d")
          ctx.fillStyle = 'rgba(255, 255, 255, 0.05)'
          ctx.fillRect(0, 0, 64, 32)
          @main.css('background-image', "url(#{canvas.toDataURL('image/png')})")

          dripcap.pubsub.sub 'core:captured-packets', (n) =>
            @packets = n
            @update()

  update: () ->
    margin = 5
    height = 32

    start = Math.max(1, Math.floor(@view.scrollTop() / height - margin))
    end = Math.min(@packets, Math.floor((@view.scrollTop() + @view.height()) / height + margin))

    @main.css('height', (height * @packets) + 'px')
    @cells.filter(':visible').each (i, ele) =>
      pos = parseInt($(ele).css('top'))
      if pos + $(ele).height() + (margin * height) < @view.scrollTop() || pos - (margin * height) > @view.scrollTop() + @view.height()
        $(ele).hide()

    if @prevStart != start || @prevEnd != end
      @prevStart = start
      @prevEnd = end
      if @session? && start <= end
        packets = []
        for i in [start..end]
          unless @cells.is("[data-packet=#{i}]:visible")
            packets.push(i)

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
          $(ele).attr('data-packet', id).toggleClass('selected', @selectedId == id).text('').css('top', (32 * (id - 1)) + 'px').show()

        @session.requestPackets(packets)

  updateTheme: (theme) ->
    @comp.updateTheme theme

  deactivate: ->
    dripcap.package.load('main-view').then (pkg) =>
      pkg.root.panel.left('packet-list-view')
      @list.unmount()
      @comp.destroy()

module.exports = PacketListView
