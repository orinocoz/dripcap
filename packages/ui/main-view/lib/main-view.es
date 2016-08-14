import $ from 'jquery';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';

export default class MainView {
  activate() {
    return new Promise(res => {
      this._comp = new Component(`${__dirname}/../less/*.less`);
      return $(() => {
        this.panel = new Panel();
        this._elem = $('<div id="main-view">').append(this.panel.root);
        this._elem.appendTo($('body'));
        return res();
      });
    });
  }

  deactivate() {
    this._elem.remove();
    return this._comp.destroy();
  }
}
