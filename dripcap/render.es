import 'coffee-script/register';
import config from 'dripcap/config';
import { shell } from 'electron';
import $ from 'jquery';

import Profile from 'dripcap/profile';
let prof = new Profile(config.profilePath + '/default');
require('dripcap')(prof);

import { remote } from 'electron';

dripcap.package.sub('core:package-loaded', () => process.nextTick(() => $('#splash').fadeOut()));
dripcap.action.on('core:new-window', () => remote.getGlobal('dripcap').newWindow());
dripcap.action.on('core:close-window', () => remote.getCurrentWindow().close());
dripcap.action.on('core:toggle-devtools', () => remote.getCurrentWindow().toggleDevTools());
dripcap.action.on('core:window-zoom', () => remote.getCurrentWindow().maximize());
dripcap.action.on('core:open-user-directroy', () => shell.showItemInFolder(config.profilePath));
dripcap.action.on('core:open-website', () => shell.openExternal('https://github.com/dripcap/dripcap'));
dripcap.action.on('core:open-wiki', () => shell.openExternal('https://github.com/dripcap/dripcap/wiki'));
dripcap.action.on('core:show-license', () => shell.openExternal('https://github.com/dripcap/dripcap/blob/master/LICENSE'));

dripcap.action.on('core:quit', () => remote.app.quit());

dripcap.action.on('core:stop-sessions', () =>
  dripcap.session.list.map((s) =>
    s.stop())
);

dripcap.action.on('core:start-sessions', function() {
  if (dripcap.session.list.length > 0) {
    return dripcap.session.list.map((s) =>
      s.start());
  } else {
    return dripcap.action.emit('core:new-session');
  }
});

remote.powerMonitor.on('suspend', () => dripcap.action.emit('core:stop-sessions'));

document.ondragover = document.ondrop = function(e) {
  e.preventDefault();
  return false;
};

$(() =>
  $(window).on('unload', () =>
    dripcap.session.list.map((s) =>
      s.close())
  )
);
