gulp = require('gulp')
coffee = require('gulp-coffee')
coffeelint = require('gulp-coffeelint')
electron = require('gulp-atom-electron')
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

gulp.task 'linux', [
    'copy'
    'coffee'
    'copypkg'
    'npm'
  ], (cb) ->
  gulp.src('./.build/**')
    .pipe(electron(version: '0.33.0', platform: 'linux'))
    .pipe(electron.zfsdest('dripcap-linux.zip'))

gulp.task 'darwin', [
    'copy'
    'coffee'
    'copypkg'
    'npm'
  ], (cb) ->
  gulp.src('./.build/**')
    .pipe(electron(version: '0.33.0', platform: 'darwin', darwinIcon: './images/dripcap.icns'))
    .pipe(electron.zfsdest('dripcap-darwin.zip'))

gulp.task 'default', [
  'lint'
  'copy'
  'coffee'
  'copypkg'
  'npm'
]

gulp.task 'watch', ->
  gulp.watch [
    './**/*.coffee'
    './**/*.tag'
    './**/*.json'
    './**/*.less'
    './**/*.cson'
  ], [
    'coffee'
    'copy'
    'copypkg'
    'npm'
  ]
