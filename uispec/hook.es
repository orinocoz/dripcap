import {
  Application
} from 'spectron'
import electron from 'electron-prebuilt';

beforeEach(function() {
  this.app = new Application({
    path: electron,
    args: ['--enable-logging', __dirname + '/../.build'],
    env: {
      'DRIPCAP_UI_TEST': '1'
    }
  });
  return this.app.start();
});

afterEach(async function() {
  if (this.app && this.app.isRunning()) {
    if (this.currentTest.state === 'failed') {
      let logs = await this.app.client.getMainProcessLogs();
      logs.forEach((log) => {
        console.log(log)
      });
      logs = await this.app.client.getRenderProcessLogs();
      logs.forEach((log) => {
        console.log(log.message);
        console.log(log.source);
      });
    }
    return this.app.stop();
  }
});
