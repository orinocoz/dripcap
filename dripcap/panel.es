import $ from 'jquery';
import _ from 'underscore';
import {
  Package
} from 'dripcap';

$.fn.extend({
  actualHeight() {
    let y = this.clone().css({
      position: 'absolute',
      visibility: 'hidden',
      display: 'block'
    }).appendTo($('body'));
    let height = y.height();
    y.remove();
    return Math.max(height, this.height());
  }
});

let html = `
  <div class="panel root">
    <div class="panel fnorth"></div>
    <div class="panel fsouth"></div>
    <div class="hcontainer">
      <div class="panel left">
        <div class="tabcontainer"></div>
        <div class="panel fnorth"></div>
        <div class="panel fsouth"></div>
        <div class="vcontainer"></div>
      </div>
      <div class="panel hcenter">
        <div class="vcontainer">
          <div class="panel top">
            <div class="tabcontainer"></div>
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="panel vcenter">
            <div class="tabcontainer"></div>
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="panel bottom">
            <div class="tabcontainer"></div>
            <div class="panel fnorth"></div>
            <div class="panel fsouth"></div>
            <div class="vcontainer"></div>
          </div>
          <div class="splitter vsplitter"></div>
          <div class="splitter vsplitter"></div>
          <div class="hover vhover"></div>
          <div class="hover vhover"></div>
        </div>
      </div>
      <div class="panel right">
        <div class="tabcontainer"></div>
        <div class="panel fnorth"></div>
        <div class="panel fsouth"></div>
        <div class="vcontainer"></div>
      </div>
      <div class="splitter hsplitter"></div>
      <div class="splitter hsplitter"></div>
      <div class="hover hhover"></div>
      <div class="hover hhover"></div>
    </div>
  </div>
`;

export default class Panel {
  constructor() {
    this.root = $(html);
    this.root.data('panel', this);

    this.update = _.debounce(() => {
      return this._update();
    }, 500);

    $(window).resize(() => this._update());
    Package.sub('core:package-loaded', () => this.update());

    this._hcontainer = this.root.children('.hcontainer');
    this._fnorthPanel = this.root.children('.fnorth');
    this._fsouthPanel = this.root.children('.fsouth');
    this._leftPanel = this._hcontainer.children('.left');
    this._fLeftNorthPanel = this._leftPanel.children('.fnorth');
    this._fLeftSouthPanel = this._leftPanel.children('.fsouth');
    this._hcenterPanel = this._hcontainer.children('.hcenter');
    this._rightPanel = this._hcontainer.children('.right');
    this._fRightNorthPanel = this._rightPanel.children('.fnorth');
    this._fRightSouthPanel = this._rightPanel.children('.fsouth');
    this._hsp0 = this._hcontainer.children('.hsplitter:eq(0)');
    this._hsp1 = this._hcontainer.children('.hsplitter:eq(1)');
    this._hh0 = this._hcontainer.children('.hhover:eq(0)');
    this._hh1 = this._hcontainer.children('.hhover:eq(1)');

    this._vcontainer = this._hcenterPanel.children('.vcontainer');
    this._topPanel = this._vcontainer.children('.top');
    this._fTopNorthPanel = this._topPanel.children('.fnorth');
    this._fTopSouthPanel = this._topPanel.children('.fsouth');
    this._centerPanel = this._vcontainer.children('.vcenter');
    this._fCenterNorthPanel = this._centerPanel.children('.fnorth');
    this._fCenterSouthPanel = this._centerPanel.children('.fsouth');
    this._bottomPanel = this._vcontainer.children('.bottom');
    this._fBottomNorthPanel = this._bottomPanel.children('.fnorth');
    this._fBottomSouthPanel = this._bottomPanel.children('.fsouth');
    this._vsp0 = this._vcontainer.children('.vsplitter:eq(0)');
    this._vsp1 = this._vcontainer.children('.vsplitter:eq(1)');
    this._vh0 = this._vcontainer.children('.vhover:eq(0)');
    this._vh1 = this._vcontainer.children('.vhover:eq(1)');

    this.root.data('v0', 0.0);
    this.root.data('v1', 1.0);
    this.root.data('h0', 0.0);
    this.root.data('h1', 1.0);

    this._vh0.hide();
    this._vh1.hide();
    this._hh0.hide();
    this._hh1.hide();
    this._vsp0.hide();
    this._vsp1.hide();
    this._hsp0.hide();
    this._hsp1.hide();

    this._vh0.on('mouseup mouseout', function() {
      return $(this).hide();
    });
    this._vh1.on('mouseup mouseout', function() {
      return $(this).hide();
    });
    this._hh0.on('mouseup mouseout', function() {
      return $(this).hide();
    });
    this._hh1.on('mouseup mouseout', function() {
      return $(this).hide();
    });

    this._vsp0.on('mousedown', () => {
      this._vh0.show();
      return false;
    });

    this._vsp1.on('mousedown', () => {
      this._vh1.show();
      return false;
    });

    this._hsp0.on('mousedown', () => {
      this._hh0.show();
      return false;
    });

    this._hsp1.on('mousedown', () => {
      this._hh1.show();
      return false;
    });

    this._vh0.on('mousemove', e => {
      let v = (e.clientY - this._vcontainer.offset().top) / this._vcontainer.height();
      let v1 = this.root.data('v1');
      if (v < v1) {
        this.root.data('v0', v);
        return this._update();
      }
    });

    this._vh1.on('mousemove', e => {
      let v = (e.clientY - this._vcontainer.offset().top) / this._vcontainer.height();
      let v0 = this.root.data('v0');
      if (v > v0) {
        this.root.data('v1', v);
        return this._update();
      }
    });

    this._hh0.on('mousemove', e => {
      let h = (e.clientX - this._hcontainer.offset().left) / this._hcontainer.width();
      let h1 = this.root.data('h1');
      if (h < h1) {
        this.root.data('h0', h);
        return this._update();
      }
    });

    this._hh1.on('mousemove', e => {
      let h = (e.clientX - this._hcontainer.offset().left) / this._hcontainer.width();
      let h0 = this.root.data('h0');
      if (h > h0) {
        this.root.data('h1', h);
        return this._update();
      }
    });

    this.update();
  }

  top(id, elem, tab) {
    let container = this._topPanel.children('.vcontainer');
    let res = container.children(`[tab-id=${id}]`).detach();
    this._vsp0.toggle(elem != null);
    if (elem == null) {
      res.removeAttr('tab-id');
      if (container.children('[tab-id]').length === 0) {
        this.root.data('v0', 0.0);
      }
      this.update();
      return res;
    }
    if (this.root.data('v1') === 1.0) {
      this.root.data('v0', 0.5);
    } else {
      this.root.data('v0', 1 / 3);
      this.root.data('v1', 2 / 3);
    }
    elem.hide().attr('tab-id', id);
    if (tab != null) {
      elem.data('tab', tab);
    }
    elem.detach().appendTo(container);
    this.update();
    return res;
  }

  topNorthFixed(elem) {
    let res = this._fTopNorthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fTopNorthPanel);
    this.update();
    return res;
  }

  topSouthFixed(elem) {
    let res = this._fTopSouthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fTopSouthPanel);
    this.update();
    return res;
  }

  northFixed(elem) {
    let res = this._fnorthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fnorthPanel);
    this.update();
    return res;
  }

  bottom(id, elem, tab) {
    let container = this._bottomPanel.children('.vcontainer');
    let res = container.children(`[tab-id=${id}]`).detach();
    this._vsp1.toggle(elem != null);
    if (elem == null) {
      res.removeAttr('tab-id');
      if (container.children('[tab-id]').length === 0) {
        this.root.data('v1', 1.0);
      }
      this.update();
      return res;
    }
    if (this.root.data('v0') === 0.0) {
      this.root.data('v1', 0.5);
    } else {
      this.root.data('v0', 1 / 3);
      this.root.data('v1', 2 / 3);
    }
    elem.hide().attr('tab-id', id);
    if (tab != null) {
      elem.data('tab', tab);
    }
    elem.detach().appendTo(container);
    this.update();
    return res;
  }

  bottomNorthFixed(elem) {
    let res = this._fBottomNorthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fBottomNorthPanel);
    this.update();
    return res;
  }

  bottomSouthFixed(elem) {
    let res = this._fBottomSouthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fBottomSouthPanel);
    this.update();
    return res;
  }

  southFixed(elem) {
    let res = this._fsouthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fsouthPanel);
    this.update();
    return res;
  }

  left(id, elem, tab) {
    let container = this._leftPanel.children('.vcontainer');
    let res = container.children(`[tab-id=${id}]`).detach();
    this._hsp0.toggle(elem != null);
    if (elem == null) {
      res.removeAttr('tab-id');
      if (container.children('[tab-id]').length === 0) {
        this.root.data('h0', 0.0);
      }
      this.update();
      return res;
    }
    if (this.root.data('h1') === 1.0) {
      this.root.data('h0', 0.5);
    } else {
      this.root.data('h0', 1 / 3);
      this.root.data('h1', 2 / 3);
    }
    elem.hide().attr('tab-id', id);
    if (tab != null) {
      elem.data('tab', tab);
    }
    elem.detach().appendTo(container);
    this.update();
    return res;
  }

  leftNorthFixed(elem) {
    let res = this._fLeftNorthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fLeftNorthPanel);
    this.update();
    return res;
  }

  leftSouthFixed(elem) {
    let res = this._fLeftSouthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fLeftSouthPanel);
    this.update();
    return res;
  }

  right(id, elem, tab) {
    let container = this._rightPanel.children('.vcontainer');
    let res = container.children(`[tab-id=${id}]`).detach();
    this._hsp1.toggle(elem != null);
    if (elem == null) {
      res.removeAttr('tab-id');
      if (container.children('[tab-id]').length === 0) {
        this.root.data('h1', 1.0);
      }
      this.update();
      return res;
    }
    if (this.root.data('h0') === 0.0) {
      this.root.data('h1', 0.5);
    } else {
      this.root.data('h0', 1 / 3);
      this.root.data('h1', 2 / 3);
    }
    elem.hide().attr('tab-id', id);
    if (tab != null) {
      elem.data('tab', tab);
    }
    elem.detach().appendTo(container);
    this.update();
    return res;
  }

  rightNorthFixed(elem) {
    let res = this._fRightNorthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fRightNorthPanel);
    this.update();
    return res;
  }

  rightSouthFixed(elem) {
    let res = this._fRightSouthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fRightSouthPanel);
    this.update();
    return res;
  }

  center(id, elem, tab) {
    let container = this._centerPanel.children('.vcontainer');
    let res = container.children(`[tab-id=${id}]`).detach();
    if (elem == null) {
      res.removeAttr('tab-id');
      this.update();
      return res;
    }
    elem.hide().attr('tab-id', id);
    if (tab != null) {
      elem.data('tab', tab);
    }
    elem.detach().appendTo(container);
    this.update();
    return res;
  }

  centerNorthFixed(elem) {
    let res = this._fCenterNorthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fCenterNorthPanel);
    this.update();
    return res;
  }

  centerSouthFixed(elem) {
    let res = this._fCenterSouthPanel.children().detach();
    if (elem == null) {
      this.update();
      return res;
    }
    elem.detach().appendTo(this._fCenterSouthPanel);
    this.update();
    return res;
  }

  _update() {
    let v0 = this.root.data('v0');
    let v1 = this.root.data('v1');
    let h0 = this.root.data('h0');
    let h1 = this.root.data('h1');

    this._topPanel.css('bottom', (100 - (v0 * 100)) + '%');
    this._centerPanel.css('top', (v0 * 100) + '%');
    this._centerPanel.css('bottom', (100 - (v1 * 100)) + '%');
    this._bottomPanel.css('top', (v1 * 100) + '%');
    this._vsp0.css('top', (v0 * 100) + '%');
    this._vsp1.css('top', (v1 * 100) + '%');

    this._leftPanel.css('right', (100 - (h0 * 100)) + '%');
    this._hcenterPanel.css('left', (h0 * 100) + '%');
    this._hcenterPanel.css('right', (100 - (h1 * 100)) + '%');
    this._rightPanel.css('left', (h1 * 100) + '%');
    this._hsp0.css('left', (h0 * 100) + '%');
    this._hsp1.css('left', (h1 * 100) + '%');

    let update = function(panel) {
      let panels = panel.children('.vcontainer').children('[tab-id]');
      let currentId = panels.filter(function() {
        return $(this).css('display') !== 'none';
      }).attr('tab-id');
      if (currentId == null && panels.length > 0) {
        currentId = panels.attr('tab-id');
      }
      let tabs = panels.get().map(function(elem) {
        let id = $(elem).attr('tab-id');
        let tab = $('<div>')
          .addClass('tab')
          .text(id)
          .toggleClass('selected', currentId === id)
          .attr('tab-id', id)
          .click(function() {
            id = $(this).attr('tab-id');
            $(this).addClass('selected').siblings().removeClass('selected');
            return $(this).parent().siblings('.vcontainer').children('[tab-id]').each((i, elem) => $(elem).toggle($(elem).attr('tab-id') === id));
          });

        if ($(elem).data('tab') != null) {
          tab.empty().append($(elem).data('tab').detach());
        }

        return tab;
      });

      panels.each((i, elem) => $(elem).toggle($(elem).attr('tab-id') === currentId));

      let tabcontainer = panel.children('.tabcontainer');
      tabcontainer.empty();
      if (tabs.length > 1) {
        return tabcontainer.append(tabs);
      }
    };

    this._hcontainer.css('top', this._fnorthPanel.actualHeight() + 'px');
    this._hcontainer.css('bottom', this._fsouthPanel.actualHeight() + 'px');

    update(this._leftPanel);
    this._leftPanel.children('.vcontainer')
      .css('top', this._fLeftNorthPanel.actualHeight() + this._leftPanel.children('.tabcontainer').actualHeight() + 'px')
      .css('bottom', this._fLeftSouthPanel.actualHeight() + 'px');

    update(this._rightPanel);
    this._rightPanel.children('.vcontainer')
      .css('top', this._fRightNorthPanel.actualHeight() + this._rightPanel.children('.tabcontainer').actualHeight() + 'px')
      .css('bottom', this._fRightSouthPanel.actualHeight() + 'px');

    update(this._topPanel);
    this._topPanel.children('.vcontainer')
      .css('top', this._fTopNorthPanel.actualHeight() + this._topPanel.children('.tabcontainer').actualHeight() + 'px')
      .css('bottom', this._fTopSouthPanel.actualHeight() + 'px');

    update(this._bottomPanel);
    this._bottomPanel.children('.vcontainer')
      .css('top', this._fBottomNorthPanel.actualHeight() + this._bottomPanel.children('.tabcontainer').actualHeight() + 'px')
      .css('bottom', this._fBottomSouthPanel.actualHeight() + 'px');

    update(this._centerPanel);
    this._centerPanel.children('.vcontainer')
      .css('top', this._fCenterNorthPanel.actualHeight() + this._centerPanel.children('.tabcontainer').actualHeight() + 'px')
      .css('bottom', this._fCenterSouthPanel.actualHeight() + 'px');
  }
}
