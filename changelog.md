# DVM Change Log

## Unreleased
### New/Changed Features
* Experimental support for FreeBSD (using Bash)
* Download DMD using platform specific archive if available
* Support for installing release candidates
* Download DMD from `downloads.dlang.org` (fallback to `ftp.digitalmars.com`)
* Set a user agent when fetching compilers. The user agent will be in the form
of `dvm/<version> (<architecture>-<operating system>)`

### Bugs Fixed
* [Issue 31](https://github.com/jacob-carlborg/dvm/issues/31): Windows: default compiler does not persist

## Version 0.4.3
### New/Changed Features
* Add support for Dub
* Since issue 23 has been fixed this means that now both 32 and 64bit
libraries are supported simultaneously

### Bugs Fixed
* Fix issue "unexpected redirect for method GET"
* [Issue 23](https://github.com/jacob-carlborg/dvm/issues/23): Leave DMD directory structure as-is

## Version 0.4.2
### New/Changed Features
* Ported to D2
* Add support for fetching the latest version of the compiler
* Bring back support for 64bit Linux

### Bugs Fixed
* Fails to get the latest version of the compiler

## Version 0.4.1
### New/Changed Features
* Issue 2: Fetch zips from github for DMD 2.057+

### Bugs Fixed
* Issue 5: Missing executable permission on some files
* Issue 9: dvm list throw an Exception when no compiler is yet installed
* Issue 11: Fails when version not explicitly specified
* Issue 13: Segmentation fault with -l

## Version 0.4.0
### New/Change Features
* Added a `compile` command for compiling DMD, druntime and Phobos from github

### Bugs Fixed
* Failed to get latest version of DMD

## Version 0.3.1
### Bugs Fixed
* `dvm use` changes the default compiler on Windows
* Can't install on Windows without administrator rights

## Version 0.3.0
### New/Change Features
* Added an option for installing the latest compiler
* Better compatibility between different shell implementations
* Added Windows support. Thanks to [Nick Sabalausky](https://github.com/Abscissa)
* Added a "list" command for listing installed compilers
* Added a "uninstall" command for uninstalling compilers

### Bugs Fixed
* Can't link using DMD 1.068.
* Issue 2: The '.dvm/bin/dmd-{ver}' scripts don't work on Ubuntu 10.04
* Issue 7: No error on invalid command
* Issue 13: Tmp dir should be deleted before running DVM binary (not just after)
* Issue 5: Invalid character in .dvm/env files
* Issue 12: "dvm -h" and "dvm --help" print nothing

## Version 0.2.0
#### New/Change Features
* 64bit version now available on Linux
* It's now possible to update an already existing DVM installation
* Added an option for installing 32bit compilers, useful on 64bit platforms
* Added support for the new structure of the DMD zip, appeared in version 1.068 and 2.053
* Added a "current" wrapper which points to the current compiler
* Added an option for specifying a default compiler
* Better compatible between different shells
* Added support for installing Tango
* Added support for installing 64bit compilers (default on 64bit platforms)
* The fetch/install command now shows progress when downloading. Thanks to [Jonas Drewsen](https://github.com/jcd)
* Added support for the new structure of the DMD zip, appeared in version 1.067 and 2.052
* Added a changelog

### Bugs Fixed
* RDMD now has executable permission
* Exit if the DVM executable cannot be found
* Always remove the temp path
* Don't use "exit" in the DVM shell script
* Added dmd.conf patch for druntime as well
* Fixed: DMD2 was incorrectly handled
* Bump version number

## Version 0.1.1
### Bugs Fixed
* Fix for: DMD couldn't find the source directory when installed

## Version 0.1
### New/Changed Features
* Initial releases
