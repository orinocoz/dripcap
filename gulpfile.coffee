gulp = require('gulp')
babel = require('gulp-babel')
coffee = require('gulp-coffee')
coffeelint = require('gulp-coffeelint')
electron = require('gulp-atom-electron')
symdest = require('gulp-symdest')
rename = require('gulp-rename')
zip = require('gulp-vinyl-zip')
runElectron = require("gulp-run-electron")
fs = require('fs')
path = require('path')
glob = require('glob')
exec = require('child_process').exec
jasmine = require('gulp-jasmine')
npm = require('npm')
require('babel-core/register')
config = require('./src/config')

gulp.task 'lint', ->
  gulp.src([
      './**/*.coffee'
    ])
    .pipe(coffeelint())
    .pipe coffeelint.reporter()

gulp.task 'babel', ->
  gulp.src('./src/**/*.js', base: './src/')
    .pipe(babel())
    .pipe gulp.dest('./.build/js/')

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
    './npm/**/*'
    './dripper/**/*'
    './msgcap/**/*'
  ], base: './')
    .pipe gulp.dest('./.build/')

gulp.task 'npm', ['copypkg'], ->
  p = new Promise (res) ->
    npm.load production: true, -> res()

  p = p.then ->
    new Promise (res) ->
      npm.prefix = './.build/'
      npm.commands.uninstall ['dripper', 'msgcap'], res

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

gulp.task 'linux', [
    'copy'
    'babel'
    'coffee'
    'copypkg'
    'npm'
  ], (cb) ->
    gulp.src('./.build/**')
      .pipe(electron(
        version: config.electronVersion,
        platform: 'linux',
        arch: 'x64',
        token: process.env['ELECTRON_GITHUB_TOKEN']))
      .pipe(zip.dest('dripcap-linux-x64.zip'))

gulp.task 'debian-pkg', (cb) ->
  gulp.src('./debian/**', base: './debian/')
    .pipe gulp.dest('./.debian/')

gulp.task 'debian-paperfilter', ['debian-bin'], (cb) ->
  gulp.src('./.debian/usr/share/dripcap/resources/app/node_modules/paperfilter/bin/paperfilter-linux')
    .pipe rename("paperfilter")
    .pipe gulp.dest('./.debian/usr/local/lib/')

gulp.task 'debian-bin', ['copy', 'coffee', 'copypkg', 'npm'], (cb) ->
  gulp.src('./.build/**')
    .pipe(electron(
      version: config.electronVersion,
      platform: 'linux',
      arch: 'x64',
      token: process.env['ELECTRON_GITHUB_TOKEN']))
    .pipe(symdest('./.debian/usr/share/dripcap'))

gulp.task 'debian', [
    'debian-bin'
    'debian-pkg'
    'debian-paperfilter'
  ]

gulp.task 'darwin', [
    'copy'
    'babel'
    'coffee'
    'copypkg'
    'npm'
  ], (cb) ->
    gulp.src('./.build/**')
      .pipe(electron(
        version: config.electronVersion,
        platform: 'darwin',
        arch: 'x64',
        token: process.env['ELECTRON_GITHUB_TOKEN'],
        darwinIcon: './images/dripcap.icns'))
      .pipe(zip.dest('dripcap-darwin.zip'))

gulp.task 'default', ['build'], ->
  gulp.src(".build").pipe(runElectron(['--enable-logging']))

gulp.task 'jasmine', ->
  gulp.src([
      './packages/**/spec/*.coffee'
      './dripper/**/spec/*.coffee'
    ])
    .pipe(jasmine())

gulp.task 'test', ['build', 'jasmine']

gulp.task 'build', [
  'babel'
  'coffee'
  'copy'
  'copypkg'
  'npm'
]

gulp.task 'watch', ['babel', 'coffee', 'copy', 'copypkg'], ->
  gulp.src(".build").pipe(runElectron(['--enable-logging']))
  gulp.watch [
    './**/*.coffee'
    './**/*.tag'
    './**/*.json'
    './**/*.less'
  ], [
    'babel'
    'coffee'
    'copy'
    'copypkg'
    runElectron.rerun
  ]
