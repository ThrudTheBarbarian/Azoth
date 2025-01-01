#!/opt/homebrew/bin/php 
<?php

// ===========================================================================
// Simple script interface to bundle all the files up into something that
// can easily be sent over to the Parallels VM and built there
//
// Creates a windows/ directory, expects to be run with $PWD being the top
// of the source tree
//
// Regenerates the windows/ directory on every run, so don't put anything in
// there that you want to keep
// ===========================================================================

$fname		= "AzothFramework";
$wdir 		= "/tmp/windows";
$fdir 		= $wdir."/".$fname;
$fsrcdir	= $fdir."/src";

// Destroy the previous run
echo " - Clearing out directory ".$wdir."\n";
system("/bin/rm -rf $wdir");

// Create the source directory
echo " - Made directory ".$fsrcdir."\n";
mkdir($fsrcdir, 0777, true);

// Find the .m and .h files and put them all in the framework source dir
$files = explode("\n",trim(`find Azoth -name '*.m' -o -name '*.h'`));
$mfiles = array();
echo " - Found ".count($files)." files to copy\n";
foreach ($files as $file)
	{
	copy($file,$fsrcdir."/".basename($file));
	
	if (str_ends_with($file, ".m"))
		$mfiles[] = "src/".basename($file);
	}

// Cope with the Azoth/xxx.h as well as xxx.h by symlinking it
system("cd $fsrcdir; ln -s . Azoth");

// Convert the mfiles array into a string
$mlist = implode(" ",$mfiles);

// Create the CMakeLists.txt that we'll use to compile the framework
$cml = "

#set(CMAKE_VERBOSE_MAKEFILE ON)
set (CMAKE_C_COMPILER clang)

cmake_minimum_required(VERSION 3.31)
project(Azoth)

set(EXECUTABLE_OUTPUT_PATH \${CMAKE_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH  \${CMAKE_BINARY_DIR}/lib)

add_library($fname SHARED $mlist)

set_target_properties($fname PROPERTIES
  FRAMEWORK TRUE
  FRAMEWORK_VERSION A
  MACOSX_FRAMEWORK_IDENTIFIER net.moebius-tech.Azoth
  # current version in semantic format in Mach-O binary file
  VERSION 16.4.0
  # compatibility version in semantic format in Mach-O binary file
  SOVERSION 1.0.0
  PUBLIC_HEADER Azoth.h
  XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY \"Sign to run locally\"
)

set_property (TARGET $fname APPEND_STRING PROPERTY 
              COMPILE_FLAGS \"-fobjc-arc\")

if(WIN32)
    #Windows specific code
elseif(APPLE)
    #OSX specific code
    
    # Find the SDL3 framework
	find_library(SDL3 SDL3 PATHS /opt/SDL3 REQUIRED)
    MESSAGE(STATUS \"SDL3 Framework found at \${SDL3}\")
	
	# Find the SDL_ttf framework
	find_library(SDL3_TTF SDL3_ttf PATHS /opt/SDL3 REQUIRED)
    MESSAGE(STATUS \"SDL3_ttf Framework found at \${SDL3_TTF}\")
	
	# Find the SDL3_image framework
	find_library(SDL3_IMAGE SDL3_image PATHS /opt/SDL3 REQUIRED)
    MESSAGE(STATUS \"SDL3_image Framework found at \${SDL3_IMAGE}\")
	
	# Find the Foundation framework
	find_library(FOUNDATION Foundation 
				 PATHS \${CMAKE_OSX_SYSROOT}/System/Library REQUIRED)
    MESSAGE(STATUS \"Foundation Framework found at \${FOUNDATION}\")
    
    # Add in the frameworks
    target_link_libraries($fname PUBLIC 
    					  \${SDL3} 
    					  \${SDL3_TTF} 
    					  \${SDL3_IMAGE}
    					  \"-framework Foundation\"
    					  )
    
    # Allow use of angle brackets to get the local framework includes
    target_include_directories($fname PRIVATE $fsrcdir)
endif()


";

file_put_contents($fdir."/CMakeLists.txt", $cml);
