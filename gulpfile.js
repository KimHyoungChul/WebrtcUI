
var gulp = require( 'gulp');
var fs = require( 'fs-extra' );
var rename = require( 'gulp-rename');
var shell = require( 'gulp-shell');
var replace = require( 'gulp-replace');
var child_process = require( 'child_process');
var zip = require( 'gulp-zip');
var rimraf = require( 'rimraf');
var del = require( 'del');
var moment = require( 'moment');
var html2js = require( 'gulp-html2js');
var sass = require( 'node-sass' );
var glob = require( 'glob' );
var css2js = require('gulp-css2js');
var merge = require( 'merge-stream' );
var concat = require( 'gulp-concat' );
var unzip = require( 'unzip' );
var request = require( 'request' );
var cordova_bin = 'node ' + __dirname + '/node_modules/cordova/bin/cordova';


// ****************************
// Utils
// ****************************
var get_git_info = function()
{
  var commit_short = child_process.execSync( 'git rev-parse --short HEAD', { encoding: 'utf8' } ).replace( /\r?\n|\r/, '' );
  var commit_timestamp = child_process.execSync( 'git log -1 --format="%ct" ' + commit_short, { encoding: 'utf8' } ).replace( /\r?\n|\r/, '' );
  var commits_count = child_process.execSync( 'git rev-list --count --all HEAD', { encoding: 'utf8' } ).replace( /\r?\n|\r/, '' );
  var branch = child_process.execSync( 'git name-rev --name-only HEAD', { encoding: 'utf8' } ).replace( /\r?\n|\r/, '' ).split( '/' ).pop();
  var tag = child_process.execSync( 'git tag -l --points-at ' + commit_short, { encoding: 'utf8' } ).replace( /\r?\n|\r/, '' );

  var info =
  {
    commit_short: commit_short,
    commit_timestamp: commit_timestamp,
    commits_count: commits_count,
    branch: branch,
    tag: tag
  };

  console.log( 'Git info: ', info );
  return info;
};



// ****************************
// Configuration
// ****************************
var git_info = get_git_info();
var build_properties = require( './build.properties.json' );
var app_version = git_info.tag || ( '0.0.0-' + moment.unix( git_info.commit_timestamp ).format( 'YYYYMMDDHHmmss' ) + '-' + git_info.commit_short + '-' + git_info.branch );

// Set build dirs
var build_testapp_dir = './builds/testapp';
var build_plugin_dir = './builds/plugin';
var build_webapp_dir = './builds/webapp';
var build_templates_dir = './builds/templates';



// ****************************
// HTML TEMPLATES TASKS
// ****************************

// Clean templates build dir
gulp.task( 'templates:clean', function( cb )
{
  fs.removeSync( build_templates_dir );
  cb();
});


// Combine html files into a single js file
gulp.task( 'templates:html:compile', function()
{
  return gulp
    .src( 'src/www/templates/src/*.html' )
    .pipe( html2js( 'html_templates.js',
    {
      adapter: 'javascript',
      useStrict: true,
      name: 'phemium_videocall_plugin_templates'
    }))
    .pipe( gulp.dest( build_templates_dir ));
});


// Replace templates path to make it easier to invoke templates.
gulp.task( 'templates:html:replace', function( cb )
{
  var contents = fs.readFileSync( build_templates_dir + '/html_templates.js' ).toString()
    .replace( /src\/www\/templates\/src\//g, '' );

  fs.writeFileSync( build_templates_dir + '/html_templates.js', contents );
  cb();
});


// Bundle Templates CSS into a JS file
gulp.task( 'templates:html:bundle', function( cb )
{
  return gulp.src( build_templates_dir + '/css/templates.css' )
    .pipe( css2js() )
    .pipe( gulp.dest( build_templates_dir ) );
});


// Combine html files into a single js file and replace path into contents
gulp.task( 'templates:html', gulp.series
(
  'templates:html:compile',
  'templates:html:replace',
  'templates:html:bundle'
));


// Process SASS to create css file
gulp.task( 'templates:sass', function( cb )
{
  fs.ensureDirSync( build_templates_dir + '/css' );

  fs.writeFileSync( build_templates_dir + '/css/templates.css', sass.renderSync(
  {
    file: 'src/www/templates/sass/all.scss',
    outputStyle: 'expanded'
  }).css.toString() );

  cb();
});


// Copy web resources
gulp.task( 'templates:resources', function( cb )
{
  fs.ensureDirSync( build_templates_dir + '/images' );
  fs.copySync( './src/www/templates/images', build_templates_dir + '/images' );
  cb();
});


// Complete templates process
gulp.task( 'templates:all', gulp.series
(
  'templates:clean',
  'templates:sass',
  'templates:html',
  'templates:resources'
));



// ****************************
// Plugin TASKS
// ****************************

// Clean templates build fir
gulp.task( 'plugin:clean', function( cb )
{
  fs.removeSync( build_plugin_dir );
  cb();
});


// Copy plugin from dist to build
gulp.task( 'plugin:copy', function()
{
  fs.copySync( './dist/plugin', build_plugin_dir );
  fs.copySync( build_templates_dir, build_plugin_dir + '/src/www/' );

  return gulp
    .src( [ 'bin/**', 'src/android/**', 'src/ios/**', 'src/www/js/**', 'README.md' ], { base: '.' } )
    .pipe( gulp.dest( build_plugin_dir ));
});


// Download phemium-softphone library
gulp.task( 'plugin:softphone', function( cb )
{
  return request( 'https://releases.phemium.com/phemium-softphone/2.5.130/phemium-softphone_2.5.130.zip' )
    .pipe( unzip.Extract( { path: build_plugin_dir + '/src/www/js' } ) );
});


// Bundle all softphone files into a single javascript file.
// ATTENTION! Do not change the order on which this files are included into gulp.src array
gulp.task( 'plugin:bundle:make', function()
{
  return gulp.src(
    [
      build_plugin_dir + '/src/www/js/sipvideocall-linphone.js',
      build_plugin_dir + '/src/www/js/sipvideocall-webrtc.js',
      build_plugin_dir + '/src/www/js/comm-webrtc-debug.js',
      build_plugin_dir + '/src/www/js/sipvideocall.js',
      build_plugin_dir + '/src/www/templates.js',
      build_plugin_dir + '/src/www/html_templates.js'
    ])
    .pipe( concat( 'sipvideocall.js' ) )
    .pipe( gulp.dest( build_plugin_dir + '/src/www' ) );
});


// Clean no need files after bundle
gulp.task( 'plugin:bundle:clean', function( cb )
{
  fs.removeSync( build_plugin_dir + '/src/www/js' );
  fs.removeSync( build_plugin_dir + '/src/www/css' );
  fs.removeSync( build_plugin_dir + '/src/www/*templates*.js' );

  cb();
});


// Bundle and clean plugin files
gulp.task( 'plugin:bundle', gulp.series( 'plugin:bundle:make', 'plugin:bundle:clean' ) );


// Prepare plugin plugin.xml file
gulp.task( 'plugin:prepare:pluginxml', function( cb )
{
  var contents = fs.readFileSync( build_plugin_dir + '/plugin.tpl.xml' ).toString()
    .replace( '{{plugin_id}}', build_properties.package.plugin.id )
    .replace( '{{plugin_name}}', build_properties.package.plugin.name )
    .replace( '{{plugin_description}}', build_properties.package.plugin.description )
    .replace( '{{plugin_version}}', app_version ).toString();

  fs.writeFileSync( build_plugin_dir + '/plugin.xml', contents );
  fs.removeSync( build_plugin_dir + '/plugin.tpl.xml' );
  cb();
});


// Prepare package.json file
gulp.task( 'plugin:prepare:packagejson', function( cb )
{
  var contents = fs.readFileSync( build_plugin_dir + '/package.tpl.json' ).toString()
    .replace( '{{plugin_name}}', build_properties.package.plugin.name )
    .replace( '{{version}}', app_version ).toString();

  fs.writeFileSync( build_plugin_dir + '/package.json', contents );
  fs.removeSync( build_plugin_dir + '/package.tpl.json' );
  cb();
});


// Plugin preparation main task
gulp.task( 'plugin:all', gulp.series
(
  'templates:all',
  'plugin:clean',
  'plugin:copy',
  'plugin:softphone',
  'plugin:bundle',
  'plugin:prepare:pluginxml',
  'plugin:prepare:packagejson'
));



// ****************************
// TESTAPP TASKS
// ****************************

// Copy test app src from dist to build
gulp.task( 'testapp:copy', function( cb )
{
  fs.copySync( './dist/testapp', build_testapp_dir );
  cb();
});


// Copy plugin files for development purposes.
// Used with testapp:devel task
gulp.task( 'testapp:copy:devel', function( cb )
{
  fs.ensureDirSync( build_testapp_dir + '/www/phemium-videocall' );

  fs.copySync( build_plugin_dir + '/src/www/sipvideocall.js', build_testapp_dir + '/www/phemium-videocall/sipvideocall.js' );
  fs.copySync( build_plugin_dir + '/src/www/images', build_testapp_dir + '/www/phemium-videocall/images' );

  cb();
});


// Watch changes into src files to rebuild test app
gulp.task( 'testapp:watch', function( cb )
{
  gulp.watch( [ './src/www/templates/sass/**/*.scss' ], gulp.series( 'templates:sass', 'templates:html', 'plugin:copy', 'plugin:softphone', 'plugin:bundle', 'testapp:copy:devel' ) );
  gulp.watch( [ './src/www/templates/src/**/*.html' ], gulp.series( 'templates:html', 'plugin:copy', 'plugin:softphone', 'plugin:bundle', 'testapp:copy:devel' ) );
  gulp.watch( [ './src/www/js/**/*.js' ], gulp.series( 'plugin:copy', 'plugin:softphone', 'plugin:bundle', 'testapp:copy:devel' ) );
  gulp.watch( [ './dist/testapp/src/**/*' ], gulp.series( 'testapp:copy:devel' ) );

  cb();
})


// Prepare config xml to package test app
gulp.task( 'testapp:prepare:configxml', function( cb )
{
  var contents = fs.readFileSync( build_testapp_dir + '/config.tpl.xml' ).toString()
    .replace( '{{app_id}}', build_properties.package.app.id )
    .replace( '{{app_name}}', build_properties.package.app.app_name )
    .replace( '{{app_description}}', build_properties.package.app.description )
    .replace( '{{app_version}}', app_version ).toString()

  fs.writeFileSync( build_testapp_dir + '/config.xml', contents );
  fs.removeSync( build_testapp_dir + '/config.tpl.xml' );
  cb();
});


// Prepare TestApp
gulp.task( 'testapp:prepare', gulp.series
(
  'testapp:prepare:configxml'
));


// Clean test app resources
gulp.task( 'testapp:clean', function( cb )
{
  fs.removeSync( build_testapp_dir );
  cb();
});


// Main testapp target
gulp.task( 'testapp:all', gulp.series
(
  'templates:all',
  'testapp:clean',
  'testapp:copy',
  'testapp:prepare'
));


// Devel testapp on your browser
gulp.task( 'testapp:devel', gulp.series( 'plugin:all', 'testapp:all', 'testapp:copy:devel', 'testapp:watch', shell.task(
[
  'cd ' + build_testapp_dir + ' && npm install --no-bin-links',
  'cd ' + build_testapp_dir + ' && ionic serve'
], { stdio:[ 0, 1, 2 ] } )));


// Minimum tasks for testapp development. It assumes testapp complete build has been already done.
gulp.task( 'testapp:devel:min', gulp.series( 'testapp:watch', shell.task(
[
  'cd ' + build_testapp_dir + ' && ionic serve'
], { stdio:[ 0, 1, 2 ] } )));



// Build iOS project
gulp.task( 'testapp:build:ios', gulp.series( 'plugin:all', 'testapp:all', function( cb )
{
  child_process.execSync( 'cd ' + build_plugin_dir + ' && npm install --no-bin-links', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && npm install --no-bin-links', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ionic build', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ' + cordova_bin + ' platform add ios', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ' + cordova_bin + ' plugin add ' + '../plugin', { stdio: [ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ' + cordova_bin + ' prepare ios', { stdio: [ 0, 1, 2 ] } );

  cb();
}));


// Build Android project
gulp.task( 'testapp:build:android', gulp.series( 'plugin:all', 'testapp:all', function( cb )
{
  child_process.execSync( 'cd ' + build_plugin_dir + ' && npm install --no-bin-links', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && npm install --no-bin-links', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ionic build', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ' + cordova_bin + ' platform add android', { stdio:[ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ' + cordova_bin + ' plugin add ' + '../plugin', { stdio: [ 0, 1, 2 ] } );
  child_process.execSync( 'cd ' + build_testapp_dir + ' && ' + cordova_bin + ' prepare android', { stdio: [ 0, 1, 2 ] } );

  cb();
}));


// /**
//  * Gulp package task
//  */


// gulp.task( 'package_plugin', [ 'plugin:prepare' ], shell.task([
//   'npm pack dist/'
// ]));

// gulp.task( 'prepare_package_name', gulp.series( 'package_plugin', function () {
//   return gulp
//     .src([build_properties.package.plugin.name + '-' + app_version + '.tgz' ])
//     .pipe(rename(build_properties.package.plugin.name + '_' + app_version + '.tgz'))
//     .pipe(gulp.dest( '.'));
// }));

// gulp.task( 'release:plugin', gulp.series( 'prepare_package_name', function()
// {
//   // Only upload tagged versions
//   if( !git_info.tag )
//   {
//     console.log( 'Not tagged version. Upload ignored.' );
//     return;
//   }

//   var file = build_properties.package.plugin.name + '_' + app_version + '.tgz';
//   child_process.execSync( 'curl -L -F "customers=sanitas,assegur,luxmed,cun,asepeyo,catalanaoccidente,racc" -F "file=@' + file + '" ' + build_properties.deploy.url, { encoding: 'utf8' } ).replace( /\r?\n|\r/, '' );
// }));






// //build android project
// gulp.task( 'android:build', gulp.series( 'testapp:configxml', 'plugin:prepare:pluginxml', 'templates:all', 'testapp:clean', shell.task([
//   'cd test && bower install --allow-root',
//   'cd test && ' + cordova_bin + ' platform add android',
//   'cd test && ' + cordova_bin + ' plugin add .. --link',
//   'cd test && ' + cordova_bin + ' build android' ]
// )));



// //run android to device/emulator
// gulp.task( 'android:run', shell.task([
//   'gulp testapp:configxml',
//   'gulp prepare_pluginxml',
//   'gulp templates:ui',
//   'gulp clean_test_app',
//   'cd test && ' + cordova_bin + ' plugin add ../ --link',
//   'cd test && ' + cordova_bin + ' platform rm android',
//   'cd test && ' + cordova_bin + ' platform add android@6.2.1',
//   'cordova run android' ]
// ));

// gulp.task( 'package_android_apk', gulp.series( 'android:build', function () {

//   gulp
//     .src( './test/platforms/android/build/outputs/apk/android-debug.apk')
//     .pipe(gulp.dest("."))
//     .pipe(rename(build_properties.package.app.name + '_' + app_version + '.apk'))
//     .pipe(gulp.dest("."));

// }));

// gulp.task( 'jenkins_app', gulp.series( 'package_android_apk', shell.task([
//   'curl -L -F \'file=@' + build_properties.package.app.name + '_' + app_version + '.apk' + '\' ' + build_properties.deploy.url
// ])));
