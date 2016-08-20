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
  async activate() {
    await Package.load('main-view');
    await Package.load('modal-dialog');

    this.comp = new Component(`${__dirname}/../tag/*.tag`);

    let n = $('<div>').addClass('container').appendTo($('body'));
    this.view = riot.mount(n[0], 'welcome-dialog')[0];
    this.view.logo = __dirname + '/../images/dripcap.png';

    Session.on('created', () => {
      this.view.hide();
      this.view.update();
    });

    Package.sub('core:package-loaded', _.once(() => {
      if (Profile.getConfig('startupDialog')) {
        this.view.show();
        this.view.update();
      }
    }));
  }

  async deactivate() {
    this.view.unmount();
    this.comp.destroy();
  }
}
