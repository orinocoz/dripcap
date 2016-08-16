<session-dialog>

  <modal-dialog>
    <h2>New session</h2>
    <p>
      <select name="interface">
        <option each={ parent.interfaceList } if={ link===1 } value={ name }>{ name }</option>
      </select>
    </p>
    <p>
      <input type="text" name="filter" placeholder="filter (BPF)">
    </p>
    <p>
      <label>
        <input type="checkbox" name="promisc">
        Promiscuous mode
      </label>
    </p>
    <p>
      <input type="button" name="start" value="Start" onclick={ parent.start }>
    </p>
  </modal-dialog>

  <style type="text/less" scoped>
    :scope > modal-dialog > .modal > .content {
      max-width: 600px;
    }
  </style>

  <script type="babel">
    import $ from 'jquery';
    import {
      Session,
      PubSub,
      Profile
    } from 'dripcap';

    this.setInterfaceList = list => {
      return this.interfaceList = list;
    };

    this.show = () => {
      return this.tags['modal-dialog'].show();
    };

    this.start = () => {
      let ifs = $(this.tags['modal-dialog'].interface).val();
      let filter = $(this.tags['modal-dialog'].filter).val();
      let promisc = $(this.tags['modal-dialog'].promisc).prop('checked');
      let snaplen = Profile.getConfig('snaplen');

      this.tags['modal-dialog'].hide();
      Session.create(ifs, {
        filter: filter,
        promiscuous: promisc,
        snaplen: snaplen
      }).then(sess => {
        sess.on('status', (stat) => {
          PubSub.pub('core:capturing-status', stat.capturing);
        });
        if (Session.list != null) {
          for (let i = 0; i < Session.list.length; i++) {
            let s = Session.list[i];
            s.close();
          }
        }
        Session.list = [sess];
        Session.emit('created', sess);
        sess.start();
      });
    };
  </script>

</session-dialog>
