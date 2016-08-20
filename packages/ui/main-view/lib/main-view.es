import $ from 'jquery';
import Component from 'dripcap/component';
import Panel from 'dripcap/panel';

export default class MainView {
  async activate() {
    this._comp = new Component(`${__dirname}/../less/*.less`);
    this.panel = new Panel();
    this._elem = $('<div id="main-view">').append(this.panel.root);
    this._elem.appendTo($('body'));
  }

  async deactivate() {
    this._elem.remove();
    this._comp.destroy();
  }
}
