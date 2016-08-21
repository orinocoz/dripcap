import assert from 'assert';

describe('packet list view', function() {
  it('shows packets', async function() {
    this.app.webContents.executeJavaScript('require("jquery")("[riot-tag=session-dialog] input[type=button]").click();');
    let selector = '[riot-tag=packet-list-view] div.packet.list-item';
    await this.app.client.waitForExist(selector, 10000);
  });
});
