/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: July 31, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.DmcInstall;

import tango.core.Exception;
import tango.io.Stdout;
import tango.io.device.File;
import tango.net.http.HttpGet;
import tango.sys.Common;
import tango.sys.Environment;
import tango.sys.Process;
import tango.sys.win32.Types;
import tango.text.convert.Format : format = Format;
import tango.text.Util;
import tango.util.compress.Zip : extractArchive;

import mambo.util.Version;

import dvm.commands.Command;
import dvm.commands.DvmInstall;
import dvm.commands.Fetch;
import dvm.commands.Use;
import mambo.core._;
import dvm.dvm.Wrapper;
import dvm.dvm._;
import Path = dvm.io.Path;
import dvm.util.Util;

// DMC is Windows-only, but this is allowed on Posix 
// in case someone wants to try to use it through Wine.

class DmcInstall : Fetch
{	
	private
	{
		string archivePath;
		string tmpCompilerPath;
		Wrapper wrapper;
		string installPath_;
	}
	
	void execute ()
	{
		install;
	}
	
private:

	void install ()
	{
		archivePath = Path.join(options.path.archives, dmcArchiveName);
		
		fetchDMC(options.path.archives);
		println("Installing: dmc");

		unpack;
		moveFiles;
		
		version (Windows)
			installWrapper;
	}

	void unpack ()
	{
		tmpCompilerPath = Path.join(options.path.tmp, "dmc");
		verbose("Unpacking:");
		verbose(options.indentation, "source: ", archivePath);
		verbose(options.indentation, "destination: ", tmpCompilerPath, '\n');
		extractArchive(archivePath, tmpCompilerPath);
	}
	
	void moveFiles ()
	{
		verbose("Moving:");
		Path.move(Path.join(tmpCompilerPath, "dm"), installPath);
	}

	version (Windows)
		void installWrapper ()
		{
			wrapper.target = Path.join(installPath, options.path.bin, "dmc.exe");
			wrapper.path = Path.join(options.path.dvm, options.path.bin, "dmc.bat");

			verbose("Installing wrapper: " ~ wrapper.path);
			wrapper.write;
		}
	
	string installPath ()
	{
		if (installPath_.length > 0)
			return installPath_;

		return installPath_ = Path.join(options.path.compilers, "dmc");
	}
}