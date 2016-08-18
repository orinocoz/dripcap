import assert from 'assert';

describe('welcome dialog', function() {
  it('shows buttons', async function() {
    let val = await this.app.client.getAttribute('[riot-tag=welcome-dialog] input[type=button]', 'value')
    assert.deepEqual(['Start a New Capturing', 'Open Preferences', 'Visit Wiki'], val);
  });

  it('shows a checkbox', async function() {
    let val = await this.app.client.getAttribute('[riot-tag=welcome-dialog] input[type=checkbox]', 'name');
    assert.equal('startup', val);
  });
});
