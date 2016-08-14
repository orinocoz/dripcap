import http from 'http';
import url from 'url';
import geit from 'geit';
import semver from 'semver';
import config from 'dripcap/config';

function createServer(cb) {
  let server = http.createServer(function(req, res) {
    let repo = geit('https://github.com/dripcap/dripcap.git');

    return repo.tree('master').then(function(tree) {
        let blobID = tree['package.json'].object;
        return repo.blob(blobID);
      })
      .then(function(data) {
        let pkg = JSON.parse(data.toString());
        if (semver.gt(pkg.version, config.version)) {
          res.writeHead(200);
          res.write(JSON.stringify({
            url: `https://github.com/dripcap/dripcap/releases/download/v${pkg.version}/dripcap-darwin-amd64.zip`
          }));
        } else {
          res.writeHead(204);
        }
        res.end();
        return server.close();
      })

    .catch(function(e) {
      console.log(e);
      res.writeHead(204);
      res.end();
      return server.close();
    });
  });

  server.listen(0, '127.0.0.1', 511, function() {
    let addr = server.address();
    return cb(url.format({
      protocol: 'http',
      hostname: addr.address,
      port: addr.port,
      path: '/'
    }));
  });

  return server;
}

export default {
  createServer: createServer
}
