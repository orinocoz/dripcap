import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';

export default class StatusView {
  activate() {
    return new Promise(res => {
      this.comp = new Component(`${__dirname}/../tag/*.tag`);
      return dripcap.package.load('main-view').then(pkg => {
        return $(() => {
          let m = $('<div/>');
          this.view = riot.mount(m[0], 'status-view')[0];
          pkg.root.panel.northFixed(m);

          dripcap.pubsub.sub('core:capturing-status', data => {
            this.view.capturing = data;
            return this.view.update();
          }
          );

          dripcap.pubsub.sub('core:capturing-settings', data => {
            this.view.settings = data;
            return this.view.update();
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
      pkg.root.panel.northFixed();
      this.view.unmount();
      return this.comp.destroy();
    }
    );
  }
}
