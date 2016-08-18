import assert from 'assert';

describe('status view', function() {
  it('shows buttons', async function() {
    let val = await this.app.client.elements('[riot-tag=status-view] span.button');
    assert.deepEqual(3, val.value.length);
  });
});
