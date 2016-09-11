import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';
import {
  Session,
  Package,
  PubSub
} from 'dripcap';

export default class BinaryView {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
    let pkg = await Package.load('main-view');

    let m = $('<div class="wrapper" />').attr('tabIndex', '0');
    pkg.root.panel.bottom('binary-view', m, $('<i class="fa fa-file-text"> Binary</i>'));

    this.view = riot.mount(m[0], 'binary-view')[0];
    let ulhex = $(this.view.root).find('.hex');
    let ulascii = $(this.view.root).find('.ascii');

    Session.on('created', function(session) {
      ulhex.empty();
      ulascii.empty();
    });

    PubSub.sub('packet-view:range', function(range) {
      ulhex.find('i').removeClass('selected');
      let r = ulhex.find('i').slice(range[0], range[1]);
      r.addClass('selected');

      ulascii.find('i').removeClass('selected');
      r = ulascii.find('i').slice(range[0], range[1]);
      r.addClass('selected');
    });

    PubSub.sub('packet-list-view:select', (pkt) => {
      this.view.set(pkt);
      this.view.update();
    });
  }

  async deactivate() {
    let pkg = await Package.load('main-view');
    pkg.root.panel.bottom('binary-view');
    this.view.unmount();
    this.comp.destroy();
  }
}
