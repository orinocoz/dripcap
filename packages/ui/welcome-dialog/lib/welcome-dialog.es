import $ from 'jquery';
import riot from 'riot';
import _ from 'underscore';
import Component from 'dripcap/component';

export default class WelcomeDialog {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return dripcap.package.load('main-view').then(pkg => {
        return dripcap.package.load('modal-dialog').then(pkg => {
          return $(() => {
            let n = $('<div>').addClass('container').appendTo($('body'));
            this.view = riot.mount(n[0], 'welcome-dialog')[0];
            this.view.logo = __dirname + '/../images/dripcap.png';

            dripcap.session.on('created', () => {
              this.view.hide();
              return this.view.update();
            }
            );

            dripcap.package.sub('core:package-loaded', _.once(() => {
              if (dripcap.profile.getConfig('startupDialog')) {
                this.view.show();
                return this.view.update();
              }
            }
            )
            );

            return res();
          }
          );
        }
        );
      }
      );
    }
    );
  }

  deactivate() {
    this.view.unmount();
    return this.comp.destroy();
  }
}
