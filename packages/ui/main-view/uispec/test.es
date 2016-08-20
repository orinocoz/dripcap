import assert from 'assert';

describe('main view', function() {
  it('shows a main panel', async function() {
    let val = await this.app.client.isExisting('div#main-view > div.panel');
    assert.ok(val);
  });
});
