import Component from 'dripcap/component';

export default class ModalDialog {
  async activate() {
    this.comp = new Component(`${__dirname}/../tag/*.tag`);
  }

  async deactivate() {
    this.comp.destroy();
  }
}
