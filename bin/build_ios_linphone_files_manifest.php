<?php

$vendorpath = 'src/ios/vendor/liblinphone-sdk';
$libpath = __DIR__ . '/../src/ios/vendor/liblinphone-sdk';
$libpath_realpath = realpath( $libpath );

$contents = '';

$directory = new RecursiveDirectoryIterator( $libpath_realpath );
$iterator = new RecursiveIteratorIterator( $directory );

// Generate "source-file"
$regex = new RegexIterator( $iterator, '/^.+\.a$/i', RecursiveRegexIterator::GET_MATCH );
$files = array_keys( iterator_to_array( $regex ) );
sort( $files );

foreach( $files as $filename )
{
  $relative_path = str_replace( $libpath_realpath, '', $filename );
  $contents .= '<source-file src="' . $vendorpath . $relative_path . '" framework="true" />' . "\n";
}

$contents .= "\n\n\n";


// Generate SDK headers
$regex = new RegexIterator( $iterator, '/^.+\.h$/i', RecursiveRegexIterator::GET_MATCH );
$files = array_keys( iterator_to_array( $regex ) );
sort( $files );

foreach( $files as $filename )
{  
  $relative_path = str_replace( $libpath_realpath, '', $filename );
  $target_dir = './liblinphone-sdk' . str_replace( '/include', '', str_replace( '/' . basename( $filename ), '', str_replace( $libpath_realpath, '', $filename ) ) );
  $contents .= '<header-file src="' . $vendorpath . $relative_path . '" target-dir="' . $target_dir . '" />' . "\n";
}


//print $contents;
file_put_contents( __DIR__ . '/linphone_ios_files_manifest.txt', $contents );
