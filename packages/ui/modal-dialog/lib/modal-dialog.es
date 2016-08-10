import $ from 'jquery';
import riot from 'riot';
import Component from 'dripcap/component';

export default class ModalDialog {
  activate() {
    return this.comp = new Component(`${__dirname}/../tag/*.tag`);
  }

  updateTheme(theme) {
    return this.comp.updateTheme(theme);
  }

  deactivate() {
    return this.comp.destroy();
  }
}
