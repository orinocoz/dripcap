import assert from 'assert';

describe('general preferences view', function() {
  it('shows a theme selector', async function() {
    let name = await this.app.client.getAttribute('[riot-tag=general-preferences-view] select', 'name')
    assert.equal('theme', name);
  });

  it('shows a snaplen option', async function() {
    let name = await this.app.client.getAttribute('[riot-tag=general-preferences-view] input', 'name')
    assert.equal('snaplen', name);
  });
});
