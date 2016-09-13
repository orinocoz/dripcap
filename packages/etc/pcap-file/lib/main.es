import $ from 'jquery';
import fs from 'fs';
import {remote} from 'electron';
const {MenuItem} = remote;
const {dialog} = remote;
import {
  Session,
  Menu,
  KeyBind,
  Action
} from 'dripcap';

class Pcap {
  constructor(path) {
    let data = fs.readFileSync(path);
    if (data.length < 24) { throw new Error('too short global header'); }

    let magicNumber = data.readUInt32BE(0, true);
    switch (magicNumber) {
      case 0xd4c3b2a1:
        var littleEndian = true;
        var nanosec = false;
        break;
      case 0xa1b2c3d4:
        littleEndian = false;
        nanosec = false;
        break;
      case 0x4d3cb2a1:
        littleEndian = true;
        nanosec = true;
        break;
      case 0xa1b23c4d:
        littleEndian = false;
        nanosec = true;
        break;
      default:
        throw new Error('wrong magic_number');
    }

    if (littleEndian) {
      this.versionMajor = data.readUInt16LE(4, true);
      this.versionMinor = data.readUInt16LE(6, true);
      this.thiszone = data.readInt16LE(8, true);
      this.sigfigs = data.readUInt32LE(12, true);
      this.snaplen = data.readUInt32LE(16, true);
      this.network = data.readUInt32LE(20, true);
    } else {
      this.versionMajor = data.readUInt16BE(4, true);
      this.versionMinor = data.readUInt16BE(6, true);
      this.thiszone = data.readInt16BE(8, true);
      this.sigfigs = data.readUInt32BE(12, true);
      this.snaplen = data.readUInt32BE(16, true);
      this.network = data.readUInt32BE(20, true);
    }

    this.packets = [];

    let offset = 24;
    while (offset < data.length) {
      if (data.length - offset < 16) { throw new Error('too short packet header'); }
      if (littleEndian) {
        var tsSec = data.readUInt32LE(offset, true);
        var tsUsec = data.readUInt32LE(offset + 4, true);
        var inclLen = data.readUInt32LE(offset + 8, true);
        var origLen = data.readUInt32LE(offset + 12, true);
      } else {
        var tsSec = data.readUInt32BE(offset, true);
        var tsUsec = data.readUInt32BE(offset + 4, true);
        var inclLen = data.readUInt32BE(offset + 8, true);
        var origLen = data.readUInt32BE(offset + 12, true);
      }

      offset += 16;
      if (data.length - offset < inclLen) { throw new Error('too short packet body'); }

      let timestamp = new Date((tsSec * 1000) + (tsUsec / 1000));
      if (nanosec) {
        timestamp = new Date((tsSec * 1000) + (tsUsec / 1000000));
      }

      let payload = data.slice(offset, offset + inclLen);
      //let linkName = linkid2name(this.network);
      let namespace = `::<${linkName}>`;
      let summary = `[${linkName}]`;

      /*
      let layer = new Layer(namespace, {name: 'Raw Frame', payload, summary});

      let packet = {
        timestamp,
        interface: '',
        options: {},
        payload,
        caplen: inclLen,
        length: origLen,
        truncated: inclLen < origLen,
        layers: {}
      };

      packet.layers[namespace] = {
        namespace,
        name: 'Raw Frame',
        payload: new PayloadSlice(0, payload.length),
        summary,
        namespace
      };

      this.packets.push(packet);
      */
      offset += inclLen;
    }
  }
}

export default class PcapFile {
  async activate() {
    KeyBind.bind('command+o', '!menu', 'pcap-file:open');

    this.fileMenu = function(menu, e) {
      menu.append(new MenuItem({
        label: 'Import Pcap File...',
        accelerator: KeyBind.get('!menu', 'pcap-file:open'),
        click: () => { return Action.emit('pcap-file:open'); }
      }));
      return menu;
    };

    Menu.registerMain('File', this.fileMenu, 5);

    Action.on('pcap-file:open', () => {
      let path = dialog.showOpenDialog(remote.getCurrentWindow(), {filters: [{name: 'PCAP File', extensions: ['pcap']}]});
      if (path != null) {
        this._open(path[0])
      }
    });

    this._drop = e => {
      e.preventDefault();
      let { files } = e.originalEvent.dataTransfer;
      if (files.length > 0 && files[0].path.endsWith('.pcap')) {
        return this._open(files[0].path);
      }
    };
  }

  _open(path) {
    let pcap = new Pcap(path);
    let sess = Session.create();
    Session.emit('created', sess);
    sess.start();

    let count = 0;

    //do (sess=sess, len=pcap.packets.length) ->
    //  sess.on 'packet', ->
    //    count++
    //    sess.close() if count >= len

    pcap.packets.map((pkt) => sess.decode(pkt));
  }

  async deactivate() {
    Action.removeAllListeners('pcap-file:open');
    KeyBind.unbind('command+o', '!menu', 'pcap-file:open');
    Menu.unregisterMain('File', this.fileMenu);
  }
}
