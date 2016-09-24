import config from 'dripcap/config';
import {
  shell
} from 'electron';
import $ from 'jquery';

import Profile from 'dripcap/profile';
let prof = new Profile(config.profilePath + '/default');
require('dripcap')(prof);

import {
  remote
} from 'electron';

import {
  Session,
  Package,
  Action
} from 'dripcap';

Package.sub('core:package-loaded', () => process.nextTick(() => $('#splash').fadeOut()));
Action.on('core:new-window', () => remote.getGlobal('dripcap').newWindow());
Action.on('core:close-window', () => remote.getCurrentWindow().close());
Action.on('core:toggle-devtools', () => remote.getCurrentWindow().toggleDevTools());
Action.on('core:window-zoom', () => remote.getCurrentWindow().maximize());
Action.on('core:open-user-directroy', () => shell.showItemInFolder(config.profilePath));
Action.on('core:open-website', () => shell.openExternal('https://dripcap.org'));
Action.on('core:open-wiki', () => shell.openExternal('https://github.com/dripcap/dripcap/wiki'));
Action.on('core:show-license', () => shell.openExternal('https://github.com/dripcap/dripcap/blob/master/LICENSE'));

Action.on('core:quit', () => remote.app.quit());

Action.on('core:stop-sessions', () =>
  Session.list.map((s) =>
    s.stop())
);

Action.on('core:start-sessions', function() {
  if (Session.list.length > 0) {
    return Session.list.map((s) =>
      s.start());
  } else {
    return Action.emit('core:new-session');
  }
});

remote.powerMonitor.on('suspend', () => Action.emit('core:stop-sessions'));

document.ondragover = document.ondrop = function(e) {
  e.preventDefault();
  return false;
};

$(() =>
  $(window).on('unload', () =>
    Session.list.map((s) =>
      s.close())
  )
);
