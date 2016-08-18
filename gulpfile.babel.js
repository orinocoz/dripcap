import gulp from 'gulp';
import babel from 'gulp-babel';
import electron from 'gulp-atom-electron';
import symdest from 'gulp-symdest';
import replace from 'gulp-replace';
import zip from 'gulp-vinyl-zip';
import sequence from 'gulp-sequence';
import runElectron from "gulp-run-electron";
import mocha from 'gulp-mocha';
import fs from 'fs';
import path from 'path';
import glob from 'glob';
import {
  exec
} from 'child_process';
import jasmine from 'gulp-jasmine';
import npm from 'npm';
import pkg from './package.json';

gulp.task('mocha', () => {
  return gulp.src(['uispec/*.es', '**/uispec/*.es'], {
      read: false
    })
    .pipe(mocha({
      reporter: 'list',
      require: ['babel-register'],
      timeout: 30000,
      slow: 10000
    }));
});

gulp.task('babel', () =>
  gulp.src('./src/**/*.es', {
    base: './src/'
  })
  .pipe(babel({
    presets: [
      "es2015-riot",
      "stage-3"
    ],
    plugins: [
      "add-module-exports", [
        "transform-runtime", {
          "polyfill": false,
          "regenerator": true
        }
      ]
    ]
  }))
  .pipe(gulp.dest('./.build/js/'))

);

gulp.task('copy', () =>
  gulp.src([
    './package.json',
    './src/*.html',
    './src/*.less'
  ])
  .pipe(gulp.dest('./.build'))

);

gulp.task('copypkg', () =>
  gulp.src([
    './packages/**/*',
    './dripcap/**/*',
    './goldfilter/**/*'
  ], {
    base: './'
  })
  .pipe(gulp.dest('./.build/'))

);

gulp.task('npm', ['copypkg'], function() {
  let p = new Promise(res => npm.load({
    production: true,
    depth: 0
  }, () => res()));


  p = p.then(() =>
    new Promise(function(res) {
      npm.prefix = './.build/';
      return npm.commands.uninstall(['dripcap', 'goldfilter'], res);
    })
  );


  p = p.then(() =>
    new Promise(function(res) {
      npm.prefix = './.build/';
      return npm.commands.install([], res);
    })
  );

  glob.sync('./.build/packages/**/package.json').forEach(function(conf) {
    let cwd = path.dirname(conf);
    return p = p.then(() =>
      new Promise(function(res) {
        npm.prefix = cwd;
        return npm.commands.install([], res);
      })
    );
  });

  return p;
});

gulp.task('linux', ['build'], cb =>
  gulp.src('./.build/**')
  .pipe(electron({
    version: pkg.engines.electron,
    platform: 'linux',
    arch: 'x64',
    token: process.env['ELECTRON_GITHUB_TOKEN']
  }))
  .pipe(zip.dest('dripcap-linux-amd64.zip'))

);

gulp.task('debian-pkg', cb =>
  gulp.src('./debian/**', {
    base: './debian/'
  })
  .pipe(replace('{{DRIPCAP_VERSION}}', pkg.version, {
    skipBinary: true
  }))
  .pipe(gulp.dest('./.debian/'))

);

gulp.task('debian-goldfilter', cb =>
  gulp.src('./.build/node_modules/goldfilter/build/goldfilter')
  .pipe(gulp.dest('./.debian/usr/bin/'))

);

gulp.task('debian-bin', ['copy', 'babel', 'copypkg', 'npm'], cb =>
  gulp.src('./.build/**')
  .pipe(electron({
    version: pkg.engines.electron,
    platform: 'linux',
    arch: 'x64',
    token: process.env['ELECTRON_GITHUB_TOKEN']
  }))
  .pipe(symdest('./.debian/usr/share/dripcap'))

);

gulp.task('debian', sequence(
  'debian-bin',
  'debian-pkg',
  'debian-goldfilter'
));

gulp.task('darwin', ['build'], cb =>
  gulp.src('./.build/**')
  .pipe(electron({
    version: pkg.engines.electron,
    platform: 'darwin',
    arch: 'x64',
    token: process.env['ELECTRON_GITHUB_TOKEN'],
    darwinBundleDocumentTypes: [{
      name: 'Libpcap File Format',
      role: 'Editor',
      ostypes: [],
      extensions: ['pcap'],
      iconFile: ''
    }],
    darwinIcon: './images/dripcap.icns'
  }))
  .pipe(symdest('./.builtapp/dripcap-darwin'))

);

gulp.task('darwin-sign', ['darwin'], cb => exec('./macdeploy.sh', () => cb()));

gulp.task('default', ['build'], function() {
  let env = {
    DRIPCAP_ATTACH: '1'
  };
  return gulp.src(".build").pipe(runElectron(['--enable-logging'], {
    env: Object.assign(env, process.env)
  }));
});

gulp.task('build', sequence(
  ['babel', 'copy', 'copypkg'],
  'npm'
));
