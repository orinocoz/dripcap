import $ from 'jquery';
import riot from 'riot';
import _ from 'underscore';
import Component from 'dripcap/component';
import {
  Session,
  Package,
  Profile
} from 'dripcap';

export default class WelcomeDialog {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return Package.load('main-view').then(pkg => {
        return Package.load('modal-dialog').then(pkg => {
          return $(() => {
            let n = $('<div>').addClass('container').appendTo($('body'));
            this.view = riot.mount(n[0], 'welcome-dialog')[0];
            this.view.logo = __dirname + '/../images/dripcap.png';

            Session.on('created', () => {
              this.view.hide();
              return this.view.update();
            });

            Package.sub('core:package-loaded', _.once(() => {
              if (Profile.getConfig('startupDialog')) {
                this.view.show();
                return this.view.update();
              }
            }));

            return res();
          });
        });
      });
    });
  }

  deactivate() {
    this.view.unmount();
    return this.comp.destroy();
  }
}
