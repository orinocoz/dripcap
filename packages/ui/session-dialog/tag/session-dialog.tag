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
      let snaplen = dripcap.profile.getConfig('snaplen');

      this.tags['modal-dialog'].hide();
      return dripcap.session.create(ifs, {
        filter: filter,
        promiscuous: promisc,
        snaplen: snaplen
      }).then(sess => {
        if (dripcap.session.list != null) {
          for (let i = 0; i < dripcap.session.list.length; i++) {
            let s = dripcap.session.list[i];
            s.close();
          }
        }
        dripcap.session.list = [sess];
        dripcap.session.emit('created', sess);
        return sess.start();
      });
    };
  </script>

</session-dialog>
