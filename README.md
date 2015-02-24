# DVM - D Version Manager

DVM allows you to easily download and install D compilers and manage different versions of the
compilers. When you switch D compiler with the `use` command the compiler will only be
available in the current shell. This allows you to have one version of the compiler in one
shell and another version in another shell. For example, have a D1 version in one shell and a
D2 version in another.

## Installation

### General Installation Instructions:

1. Download the DVM tool form: https://github.com/jacob-carlborg/dvm/releases
2. Add executable permissions to the downloaded file.
3. Run the installation: `$ ./<dvm> install dvm` (where `<dvm>` is the name of the downloaded file)

### Example of installation:

#### Mac OS X:

    $ curl -L -o dvm https://github.com/jacob-carlborg/dvm/releases/download/v0.4.3/dvm-0.4.3-osx && chmod +x dvm && ./dvm install dvm

#### Linux 64bit

    $ curl -L -o dvm https://github.com/jacob-carlborg/dvm/releases/download/v0.4.3/dvm-0.4.3-linux-debian7-x86_64 && chmod +x dvm && ./dvm install dvm

#### Linux 32bit

    $ curl -L -o dvm https://github.com/jacob-carlborg/dvm/releases/download/v0.4.3/dvm-0.4.3-linux-debian6-x86 && chmod +x dvm && ./dvm install dvm

#### Windows

Follow the general installation instructions.
https://github.com/jacob-carlborg/dvm/releases/download/v0.4.3/dvm-0.4.3-win.exe

#### Upgrading from 0.2.0 to 0.3.0

It might be necessary to do a complete clean installation by removing ~/.dvm. This is in
particular if you had any problems with the previous shell scripts not working.

## Usage

### Install Compilers

* Install a D compiler (DMD): `$ dvm install 2.064.2`
* Install a D compiler (DMD) with Tango as the standard library: `$ dvm install 1.072 -t`

### Use a Compiler

* Use a D compiler (DMD): `$ dvm use 2.064.2`
* Use a D compiler (DMD) and set it to default: `$ dvm use 2.064.2 -d`
* Show usage information: `$ dvm -h`

## License

The source code is available under the [Boost Software License 1.0](http://www.boost.org/LICENSE_1_0.txt)

## Limitations

* Currently DMD is the only supported compiler

## Build Dependencies

* [Dub](http://code.dlang.org/download)

## Build Instructions

1. Run Dub in the directory of the cloned repository: `$ dub build`