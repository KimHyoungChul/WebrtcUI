var fs = require( 'fs' );
var xcode = require( 'xcode' );
var path = require( 'path' );

var rootDir = process.cwd();

// Extract project name from config.xml
var config_xml_contents = fs.readFileSync( rootDir + '/config.xml', 'utf8' );
var projectName = config_xml_contents.match( /\<name\>(.*)\<\/name\>/gi )[0].split( '>' )[1].split('<')[0];

// Define pbxproj file
var pbxproj_file = rootDir + '/platforms/ios/' + projectName + '.xcodeproj/project.pbxproj';

// Edit pbxproj file
var data = fs.readFileSync( pbxproj_file, 'utf8' );

// Check if it is already modified
if( data.indexOf( 'GCC_PREPROCESSOR_DEFINITIONS' ) > -1 )
{
  console.info( '[Phemium] Already modified' );
}
else
{
  // Add linphone paths and definitions
  data = data.replace( /GCC_PREFIX_HEADER/g, 'GCC_PREPROCESSOR_DEFINITIONS = ( IN_LINPHONE, VIDEO_ENABLED, HAVE_X264, HAVE_SILK, HAVE_G729, HAVE_AMR, ); GCC_PREFIX_HEADER' );
  fs.writeFileSync( pbxproj_file, data, 'utf8' );

  var build_xcconfig_file = rootDir + '/platforms/ios/cordova/build.xcconfig';
  var build_file_contents = fs.readFileSync( build_xcconfig_file, 'utf8' );
  build_file_contents = build_file_contents.replace( /(HEADER_SEARCH_PATHS.*)/g, '$1 ' + '"$(SRCROOT)/' + projectName + '/Plugins/**"' );  
  fs.writeFileSync( build_xcconfig_file, build_file_contents, 'utf8' );

  console.info( bridge_header_file + ':' + fs.readFileSync );
  var bridge_header_file = rootDir + '/platforms/ios/' + projectName + '/Bridging-Header.h';
  fs.appendFileSync(bridge_header_file, '\n' + '#import \"cordova-plugin-iosrtc-Bridging-Header.h\"');
 
  console.info( '[Phemium] Files modified' );
}
