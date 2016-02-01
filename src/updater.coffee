http = require('http')
url = require('url')
geit = require('geit')
semver = require('semver')
config = require('dripcap/config')

exports.createServer = (cb) ->
  server = http.createServer (req, res) ->
    repo = geit('https://github.com/dripcap/dripcap.git')

    repo.tree('master').then (tree) ->
      blobID = tree['package.json'].object;
      repo.blob(blobID)
    .then (data) ->
      pkg = JSON.parse(data.toString())
      if semver.gt(pkg.version, config.version)
        res.writeHead(200)
        res.write(JSON.stringify(url: "https://github.com/dripcap/dripcap/releases/download/v#{pkg.version}/dripcap-darwin-amd64.zip"))
      else
        res.writeHead(204)
      res.end()
      server.close()

    .catch (e) ->
      console.log(e)
      res.writeHead(204)
      res.end()
      server.close()

  server.listen 0, '127.0.0.1', 511, ->
    addr = server.address()
    cb url.format(protocol: 'http', hostname: addr.address, port: addr.port, path: '/')

  server
