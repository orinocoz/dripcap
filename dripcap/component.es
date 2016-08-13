import $ from 'jquery';
import riot from 'riot';
import less from 'less';
import fs from 'fs';
import glob from 'glob';

const tagPattern = /riot\.tag\('([a-z-]+)'/ig;

export default class Component {
  constructor() {
    this._less = '';
    this._names = [];

    let babel = riot.parsers.js.babel;
    riot.parsers.js.babel = (js, opts, url) => {
      return babel(js, opts, __dirname);
    };

    riot.parsers.css.less = (tag, css) => {
      this._less += css;
      return '';
    };

    const tags = arguments;
    for (let pattern of tags) {
      for (let tag of glob.sync(pattern)) {
        if (tag.endsWith('.tag')) {
          let data = fs.readFileSync(tag, {encoding: 'utf8'});
          let code = "riot = require('riot');\n" + riot.compile(data);
          let match;
          while (match = tagPattern.exec(code)) {
            this._names.push(match[1]);
          }
          new Function(code)();
        } else if (tag.endsWith('.less')) {
          this._less += `\n@import "${tag}";\n`;
        }
      }
    }

    less.render(this._less, (e, output) => {
      if (e != null) {
        throw e;
      } else {
        $('<style>').text(output.css).appendTo($('head'));
      }
    });
  }

  destroy() {
    for (let name of this._names) {
      riot.tag(name, '');
    }
    this._css.remove();
  }
}
