gulp = require('gulp')
coffee = require('gulp-coffee')
coffeelint = require('gulp-coffeelint')
electron = require('gulp-atom-electron')
symdest = require('gulp-symdest')
replace = require('gulp-replace')
zip = require('gulp-vinyl-zip')
sequence = require('gulp-sequence')
runElectron = require("gulp-run-electron")
fs = require('fs')
path = require('path')
glob = require('glob')
exec = require('child_process').exec
jasmine = require('gulp-jasmine')
npm = require('npm')
pkg = require('./package.json')

gulp.task 'lint', ->
  gulp.src([
      './**/*.coffee'
    ])
    .pipe(coffeelint())
    .pipe coffeelint.reporter()

gulp.task 'coffee', ->
  gulp.src('./src/**/*.coffee', base: './src/')
    .pipe(coffee())
    .pipe gulp.dest('./.build/js/')

gulp.task 'copy', ->
  gulp.src([
      './package.json'
      './src/*.html'
      './src/*.less'
    ])
    .pipe gulp.dest('./.build')

gulp.task 'copypkg', ->
  gulp.src([
    './packages/**/*'
    './dripcap/**/*'
    './paperfilter/**/*'
    './goldfilter/**/*'
    './msgcap/**/*'
  ], base: './')
    .pipe gulp.dest('./.build/')

gulp.task 'npm', ['copypkg'], ->
  p = new Promise (res) ->
    npm.load {production: true, depth: 0}, -> res()

  p = p.then ->
    new Promise (res) ->
      npm.prefix = './.build/'
      npm.commands.uninstall ['dripcap', 'msgcap'], res

  p = p.then ->
    new Promise (res) ->
      npm.prefix = './.build/'
      npm.commands.install [], res

  glob.sync('./.build/packages/**/package.json').forEach (conf) ->
    cwd = path.dirname(conf)
    p = p.then ->
      new Promise (res) ->
        npm.prefix = cwd
        npm.commands.install [], res

  p

gulp.task 'linux', ['build'], (cb) ->
    gulp.src('./.build/**')
      .pipe(electron(
        version: pkg.engines.electron,
        platform: 'linux',
        arch: 'x64',
        token: process.env['ELECTRON_GITHUB_TOKEN']))
      .pipe(zip.dest('dripcap-linux-amd64.zip'))

gulp.task 'debian-pkg', (cb) ->
  gulp.src('./debian/**', base: './debian/')
    .pipe(replace('{{DRIPCAP_VERSION}}', pkg.version, skipBinary: true))
    .pipe gulp.dest('./.debian/')

gulp.task 'debian-paperfilter', (cb) ->
  gulp.src('./.build/node_modules/paperfilter/bin/paperfilter')
    .pipe gulp.dest('./.debian/usr/bin/')

gulp.task 'debian-bin', ['copy', 'coffee', 'copypkg', 'npm'], (cb) ->
  gulp.src('./.build/**')
    .pipe(electron(
      version: pkg.engines.electron,
      platform: 'linux',
      arch: 'x64',
      token: process.env['ELECTRON_GITHUB_TOKEN']))
    .pipe(symdest('./.debian/usr/share/dripcap'))

gulp.task 'debian', sequence(
  'debian-bin',
  'debian-pkg',
  'debian-paperfilter'
)

gulp.task 'darwin', ['build'], (cb) ->
    gulp.src('./.build/**')
      .pipe(electron(
        version:  pkg.engines.electron,
        platform: 'darwin',
        arch: 'x64',
        token: process.env['ELECTRON_GITHUB_TOKEN'],
        darwinBundleDocumentTypes: [
          name: 'Libpcap File Format'
          role: 'Editor'
          ostypes: []
          extensions: ['pcap']
          iconFile: ''
        ]
        darwinIcon: './images/dripcap.icns'))
      .pipe(symdest('./.builtapp/dripcap-darwin'))

gulp.task 'darwin-sign', ['darwin'], (cb) ->
  exec './macdeploy.sh', -> cb()

gulp.task 'default', ['build'], ->
  gulp.src(".build").pipe(runElectron(['--enable-logging'], env: Object.assign({
      DRIPCAP_ATTACH: '1'
    }, process.env)))

gulp.task 'jasmine', ->
  gulp.src([
      './packages/**/spec/*.coffee'
      './dripcap/spec/*.coffee'
      './msgcap/spec/*.coffee'
    ])
    .pipe(jasmine())

gulp.task 'test', sequence('build', 'jasmine', 'uitest')

gulp.task 'uitest', ->
  gulp.src(".build").pipe(runElectron([], env: Object.assign({
      DRIPCAP_UI_TEST: __dirname
      PAPERFILTER_TESTDATA: path.join __dirname, 'uispec/test'
    }, process.env)))

gulp.task 'build', sequence(
  ['coffee', 'copy', 'copypkg'],
  'npm'
)
