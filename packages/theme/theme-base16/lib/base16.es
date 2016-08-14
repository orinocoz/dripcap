export default class Base16 {
  activate() {
    dripcap.theme.register('base16-mocha-dark', {
      name: "Mocha Dark",
      less: [`${__dirname}/../less/mocha-dark.less`]
    });

    dripcap.theme.register('base16-ocean-light', {
      name: "Ocean Light",
      less: [`${__dirname}/../less/ocean-light.less`]
    });

    return dripcap.theme.register('base16-atelier-estuary-light', {
      name: "Atelier Estuary Light",
      less: [`${__dirname}/../less/atelier-estuary-light.less`]
    });
  }

  deactivate() {
    dripcap.theme.unregister('base16-mocha-dark');
    dripcap.theme.unregister('base16-ocean-light');
    return dripcap.theme.unregister('base16-atelier-estuary-light');
  }
}
