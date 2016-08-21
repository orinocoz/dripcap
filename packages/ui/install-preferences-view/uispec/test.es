import assert from 'assert';

this.installing = false;
this.message = '';
this.packageList = [];

describe('install preferences view', function() {
  it('shows packages', async function() {
    this.app.webContents.executeJavaScript('require("dripcap").Action.emit("core:preferences");');
    let selector = '[riot-tag=install-preferences-view] install-preferences-view-item';
    await this.app.client.waitForExist(selector, 10000);
  });
});
