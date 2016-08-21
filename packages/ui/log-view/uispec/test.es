import assert from 'assert';

describe('log view', function() {
  it('shows logs', async function() {
    this.app.webContents.executeJavaScript('require("dripcap").Action.emit("log-view:toggle");');
    await this.app.client.waitForExist('[riot-tag=log-view] li');
  });
});
