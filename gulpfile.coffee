gulp = require('gulp')
coffee = require('gulp-coffee')
coffeelint = require('gulp-coffeelint')
electron = require('gulp-atom-electron')
runElectron = require("gulp-run-electron")
fs = require('fs')
path = require('path')
glob = require('glob')
exec = require('child_process').exec
jasmine = require('gulp-jasmine')
npm = require('npm')

gulp.task 'test', ->
  gulp.src([
      './packages/**/spec/*.coffee'
    ])
    .pipe(jasmine())

gulp.task 'lint', ->
  gulp.src([
      './src/*.coffee'
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
      './src/*.cson'
    ])
    .pipe gulp.dest('./.build')

gulp.task 'copypkg', ->
  gulp.src(['./packages/**/*', './npm/**/*'], base: './')
    .pipe gulp.dest('./.build/')

gulp.task 'npm', ['copypkg'], ->
  p = new Promise (res) ->
    npm.load production: true, -> res()

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
    'coffee'
    'copypkg'
    'npm'
  ], (cb) ->
  gulp.src('./.build/**')
    .pipe(electron(version: '0.33.8', platform: 'linux', arch: 'x64', token: process.env['ELECTRON_GITHUB_TOKEN']))
    .pipe(electron.zfsdest('dripcap-linux-x64.zip'))

gulp.task 'darwin', [
    'copy'
    'coffee'
    'copypkg'
    'npm'
  ], (cb) ->
  gulp.src('./.build/**')
    .pipe(electron(version: '0.33.8', platform: 'darwin', arch: 'x64', token: process.env['ELECTRON_GITHUB_TOKEN'], darwinIcon: './images/dripcap.icns'))
    .pipe(electron.zfsdest('dripcap-darwin.zip'))

gulp.task 'default', ['build'], ->
  gulp.src(".build").pipe(runElectron())

gulp.task 'build', [
  'coffee'
  'copy'
  'copypkg'
  'npm'
]

gulp.task 'watch', ['build'], ->
  gulp.src(".build").pipe(runElectron())
  gulp.watch [
    './**/*.coffee'
    './**/*.tag'
    './**/*.json'
    './**/*.less'
    './**/*.cson'
  ], [
    'build'
    runElectron.rerun
  ]
