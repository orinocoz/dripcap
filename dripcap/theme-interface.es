import PubSub from './pubsub';

export default class ThemeInterface extends PubSub {
  constructor(parent) {
    super();
    this.parent = parent;
    this.registry = {};

    this._defaultScheme = {
      name: 'Default',
      less: [`${__dirname}/theme.less`]
    };

    this.register('default', this._defaultScheme);
    this.id = 'default';
  }

  register(id, scheme) {
    this.registry[id] = scheme;
    this.pub('registryUpdated', null, 1);
    if (this._id === id) {
      this.scheme = this.registry[id];
      this.pub('update', this.scheme, 1);
    }
  }

  unregister(id) {
    delete this.registry[id];
    this.pub('registryUpdated', null, 1);
  }

  get id() {
    return this._id;
  }

  set id(id) {
    if (id != this._id) {
      this._id = id;
      this.parent.profile.setConfig('theme', id);
      if (this.registry[id] != null) {
        this.scheme = this.registry[id];
        this.pub('update', this.scheme, 1);
      }
    }
  }
}
