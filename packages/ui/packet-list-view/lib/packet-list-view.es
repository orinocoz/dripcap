import $ from 'jquery';
import _ from 'underscore';
import riot from 'riot';
import fs from 'fs';
import Component from 'dripcap/component';
import {
  remote
} from 'electron';
let {
  Menu
} = remote;
let {
  MenuItem
} = remote;
let {
  dialog
} = remote;
import {
  Session,
  Package,
  PubSub
} from 'dripcap';

export default class PacketListView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return Package.load('main-view').then(pkg => {
        $(() => {
          let m = $('<div class="wrapper noscroll" />');
          pkg.root.panel.left('packet-list-view', m);

          let n = $('<div class="wrapper" />').attr('tabIndex', '0').appendTo(m);
          this.list = riot.mount(n[0], 'packet-list-view', {
            items: []
          })[0];

          this.view = $('[riot-tag=packet-list-view]');
          this.view.scroll(_.debounce((() => this.update()), 100));

          PubSub.sub('core:session-packet', pkt => {
            if (pkt.id === this.selectedId) {
              PubSub.pub('packet-list-view:select', pkt);
            }
            process.nextTick(() => {
              this.cells.filter(`[data-packet=${pkt.id}]:visible`)
                .empty()
                .append($('<a>').text(pkt.name))
                .append($('<a>').text(pkt.attrs.src))
                .append($('<a>').append($('<i class="fa fa-angle-double-right">')))
                .append($('<a>').text(pkt.attrs.dst))
                .append($('<a>').text(pkt.len));
            });
          });

          this.main = $('[riot-tag=packet-list-view] div.main');

          let canvas = $("<canvas width='64' height='64'>")[0];
          let ctx = canvas.getContext("2d");
          ctx.fillStyle = 'rgba(255, 255, 255, 0.05)';
          ctx.fillRect(0, 0, 64, 32);
          this.main.css('background-image', `url(${canvas.toDataURL('image/png')})`);

          PubSub.sub('packet-filter-view:filter', filter => {
            this.filtered = 0;
            this.reset();
            this.update();
          });

          PubSub.sub('core:session-created', session => {
            this.session = session;
            this.packets = 0;
            this.filtered = -1;
            this.reset();
            this.update();
          });

          PubSub.sub('core:capturing-status', n => {
            this.packets = n.packets;

            if (n.filtered.main != null) {
              this.filtered = n.filtered.main;
            } else {
              this.filtered = -1;
            }

            this.update();
          });

          this.reset();
          res();
        });
      });
    });
  }

  reset() {
    this.prevStart = -1;
    this.prevEnd = -1;
    this.selectedId = -1;
    this.main.empty();
    this.cells = $([]);
  }

  update() {
    let margin = 5;
    let height = 32;

    let num = this.packets;
    if (this.filtered !== -1) {
      num = this.filtered;
    }

    if (num > 0 && this.view.height() === 0) {
      setTimeout(() => {
        this.update();
      }, 500);
    }

    this.main.css('height', (height * num) + 'px');
    let start = Math.max(1, Math.floor((this.view.scrollTop() / height) - margin));
    let end = Math.min(num, Math.floor(((this.view.scrollTop() + this.view.height()) / height) + margin));

    this.cells.filter(':visible').each((i, ele) => {
      let pos = parseInt($(ele).css('top'));
      if (pos + $(ele).height() + (margin * height) < this.view.scrollTop() || pos - (margin * height) > this.view.scrollTop() + this.view.height()) {
        $(ele).hide();
      }
    });

    if (this.prevStart !== start || this.prevEnd !== end) {
      this.prevStart = start;
      this.prevEnd = end;
      if ((this.session != null) && start <= end) {
        if (this.filtered === -1) {
          let list = [];
          let iterable = __range__(start, end, true);
          for (let j = 0; j < iterable.length; j++) {
            let i = iterable[j];
            list.push(i);
          }
          this.updateCells(start - 1, list);
        } else {
          this.session.getFiltered('main', start, end).then(list => {
            this.updateCells(start - 1, list);
          });
        }
      }
    }
  }

  updateCells(start, list) {
    let packets = [];
    let indices = [];
    for (let n = 0; n < list.length; n++) {
      let id = list[n];
      if (!this.cells.is(`[data-packet=${id}]:visible`)) {
        packets.push(id);
        indices.push(start + n);
      }
    }

    let needed = packets.length - this.cells.filter(':not(:visible)').length;
    if (needed > 0) {
      let iterable = __range__(1, (needed), true);
      for (let j = 0; j < iterable.length; j++) {
        let i = iterable[j];
        let self = this;
        $('<div class="packet list-item">').appendTo(this.main).hide().click(function() {
          $(this).siblings('.selected').removeClass('selected');
          $(this).addClass('selected');
          self.selectedId = parseInt($(this).attr('data-packet'));
          process.nextTick(() => {
            self.session.requestPackets([self.selectedId]);
          });
        });
      }

      this.cells = this.main.children('div.packet');
    }

    this.cells.filter(':not(:visible)').each((i, ele) => {
      if (i >= packets.length) {
        return;
      }
      let id = packets[i];
      $(ele).attr('data-packet', id).toggleClass('selected', this.selectedId === id).empty().css('top', (32 * indices[i]) + 'px').show();
    });

    this.session.requestPackets(packets);
  }

  deactivate() {
    Package.load('main-view').then(pkg => {
      pkg.root.panel.left('packet-list-view');
      this.list.unmount();
      this.comp.destroy();
    });
  }
}

function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}
