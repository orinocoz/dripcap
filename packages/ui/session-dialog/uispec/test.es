import assert from 'assert';

describe('session dialog', function() {
  it('shows an interface list', async function() {
    let val = await this.app.client.getAttribute('[riot-tag=session-dialog] select[name=interface] option', 'value')
    assert.deepEqual(['eth0', 'lo'], val);
  });
  it('shows a start button', async function() {
    let val = await this.app.client.getAttribute('[riot-tag=session-dialog] input[type=button]', 'value')
    assert.equal('Start', val);
  });
});
