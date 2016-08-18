import assert from 'assert';

describe('application launch', function() {
  it('shows an initial window', async function() {
    let count = await this.app.client.getWindowCount();
    assert.equal(count, 1);
  });
});
