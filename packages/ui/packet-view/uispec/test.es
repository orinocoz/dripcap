import assert from 'assert';

describe('packet view', function() {
  it('shows layers', async function() {
    this.app.webContents.executeJavaScript('require("jquery")("[riot-tag=session-dialog] input[type=button]").click();');
    let item = '[riot-tag=packet-list-view] div.packet.list-item';
    await this.app.client.waitForExist(item, 10000);
    this.app.webContents.executeJavaScript(`require("jquery")("${item}").click();`);
    let layer = '[riot-tag=packet-view] p.layer-name';
    await this.app.client.waitForExist(layer, 10000);
  });
});
