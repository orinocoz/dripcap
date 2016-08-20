import assert from 'assert';

describe('package preferences view', function() {
  it('shows packages', async function() {
    let val = await this.app.client.elements('[riot-tag=package-preferences-view] package-preferences-view-item')
    assert.ok(val.value.length > 0);
  });
});
