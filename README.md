# DVM - D Version Manager

DVM allows you to easily download and install D compilers and manage different versions of the
compilers. When you switch D compiler with the `use` command the compiler will only be
available in the current shell. This allows you to have one version of the compiler in one
shell and another version in another shell. For example, have a D1 version in one shell and a
D2 version in another.

## Installation

### General Installation Instructions:

1. Download the DVM tool form: https://github.com/jacob-carlborg/dvm/downloads
2. Add executable permissions to the downloaded file.
3. Run the installation: `$ ./<dvm> install dvm` (where `<dvm>` is the name of the downloaded file) 

### Example of installation:

#### Mac OS X:

	$ curl -L -o dvm https://github.com/downloads/jacob-carlborg/dvm/dvm-0.4.1-osx && chmod +x dvm && ./dvm install dvm

#### Linux 32bit

	$ curl -L -o dvm https://github.com/downloads/jacob-carlborg/dvm/dvm-0.4.1-linux-32 && chmod +x dvm && ./dvm install dvm 

#### Windows

Follow the general installation instructions.
https://github.com/downloads/jacob-carlborg/dvm/dvm-0.4.1-win.exe

#### Upgrading from 0.2.0 to 0.3.0

It might be necessary to do a complete clean installation by removing ~/.dvm. This is in
particular if you had any problems with the previous shell scripts not working.

## Usage

### Install Compilers

* Install a D compiler (DMD): `$ dvm install 2.060`
* Install a D compiler (DMD) with Tango as the standard library: `$ dvm install 1.068 -t`

If you're running a Linux 64bit operating system you most likely want to install a 64bit
version of DMD. Add the `--64bit` flag to install a 64bit version of DMD.

### Use a Compiler

* Use a D compiler (DMD): `$ dvm use 2.060`
* Use a D compiler (DMD) and set it to default: `$ dvm use 2.060 -d`
* Show usage information: `$ dvm -h`

## License

The source code is available under the [Boost Software License 1.0](http://www.boost.org/LICENSE_1_0.txt)

## Limitations

* Currently DMD is the only supported compiler
* The Linux 64bit version had to be withdrawn due to a bug in Tango

## Build Dependencies

* A D1 compiler: http://www.digitalmars.com/d/1.0/changelog.html
* Tango: http://www.dsource.org/projects/tango (revision 5620 or newer)
* DSSS: http://www.dsource.org/projects/dsss
* zlib: http://zlib.net
* Git: http://git-scm.com (to clone the repository) 

## Build Instructions

1. Clone the repository: `$ git clone git://github.com/jacob-carlborg/dvm.git`
2. Change to the newly created directory
3. Run: `$ dsss build`