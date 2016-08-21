import assert from 'assert';

describe('binary view', function() {
  it('shows hex', async function() {
    this.app.webContents.executeJavaScript('require("jquery")("[riot-tag=session-dialog] input[type=button]").click();');
    let item = '[riot-tag=packet-list-view] div.packet.list-item';
    await this.app.client.waitForExist(item, 10000);
    this.app.webContents.executeJavaScript(`require("jquery")("${item}").click();`);
    let hex = '[riot-tag=binary-view] i.list-item';
    await this.app.client.waitForExist(hex, 10000);
  });
});
