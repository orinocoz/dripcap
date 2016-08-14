import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';

export default class BinaryView {

  activate() {
      return new Promise(res => {
            this.comp = new Component(`${__dirname}/../tag/*.tag`);
            return dripcap.package.load('main-view').then(pkg => {
                  return $(() => {
                        let m = $('<div class="wrapper" />').attr('tabIndex', '0');
                        pkg.root.panel.bottom('binary-view', m, $('<i class="fa fa-file-text"> Binary</i>'));

                        this.view = riot.mount(m[0], 'binary-view')[0];
                        let ulhex = $(this.view.root).find('.hex');
                        let ulascii = $(this.view.root).find('.ascii');

                        dripcap.session.on('created', function(session) {
                          ulhex.empty();
                          return ulascii.empty();
                        });

                        dripcap.pubsub.sub('packet-view:range', function(range) {
                          ulhex.find('i').removeClass('selected');
                          let r = ulhex.find('i').slice(range[0], range[1]);
                          r.addClass('selected');

                          ulascii.find('i').removeClass('selected');
                          r = ulascii.find('i').slice(range[0], range[1]);
                          return r.addClass('selected');
                        });

                        dripcap.pubsub.sub('packet-list-view:select', function(pkt) {
                              ulhex.empty();
                              ulascii.empty();

                              let {
                                payload
                              } = pkt;

                              let hexhtml = '';
                              let asciihtml = '';

                              for (let i = 0; i < payload.length; i++) {
                                var b = payload[i];
                                hexhtml += `<i class="list-item">${(`0${b.toString(16)}`).slice(-2)}</i>`;
            }

            for (let j = 0; j < payload.length; j++) {
              var b = payload[j];
              let text =
                0x21 <= b && b <= 0x7e ?
                  String.fromCharCode(b)
                :
                  '.';
              asciihtml += `<i class="list-item">${text}</i>`;
            }

            return process.nextTick(function() {
              ulhex[0].innerHTML = hexhtml;
              return ulascii[0].innerHTML = asciihtml;
            });
          }
          );

          return res();
        }
        );
      }
      );
    }
    );
  }

  deactivate() {
    return dripcap.package.load('main-view').then(pkg => {
      pkg.root.panel.bottom('binary-view');
      this.view.unmount();
      return this.comp.destroy();
    }
    );
  }
}
