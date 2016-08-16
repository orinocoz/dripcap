import {
  Theme
} from 'dripcap';

export default class Base16 {
  activate() {
    Theme.register('base16-mocha-dark', {
      name: "Mocha Dark",
      less: [`${__dirname}/../less/mocha-dark.less`]
    });

    Theme.register('base16-ocean-light', {
      name: "Ocean Light",
      less: [`${__dirname}/../less/ocean-light.less`]
    });

    Theme.register('base16-atelier-estuary-light', {
      name: "Atelier Estuary Light",
      less: [`${__dirname}/../less/atelier-estuary-light.less`]
    });
  }

  deactivate() {
    Theme.unregister('base16-mocha-dark');
    Theme.unregister('base16-ocean-light');
    Theme.unregister('base16-atelier-estuary-light');
  }
}
