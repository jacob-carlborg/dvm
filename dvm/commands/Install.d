/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Install;

import tango.core.Exception;
import tango.io.device.File;
import tango.net.http.HttpGet;
import tango.sys.Common;
import tango.sys.Process;
import tango.sys.win32.Types;
import tango.text.convert.Format : format = Format;
import tango.text.Util;
import tango.util.compress.Zip : extractArchive;

import dvm.commands.Command;
import dvm.commands.DvmInstall;
import dvm.commands.Fetch;
import dvm.commands.Use;
import dvm.core._;
import dvm.dvm.Wrapper;
import dvm.dvm._;
import Path = dvm.io.Path;
import dvm.util.Util;
import dvm.util.Version;

class Install : Fetch
{	
	private
	{
		string archivePath;
		string tmpCompilerPath;
		string installPath_;
		Wrapper wrapper;
		
		static if (darwin)
			const platform = "osx";
		
		else static if (freebsd)
			const platform = "freebsd";
		
		else static if (linux)
			const platform = "linux";
		
		else static if (Windows)
			const platform = "windows";
	}
	
	this ()
	{
		super("install", "Install one or many D versions.");
	}
	
	void execute ()
	{
		if (args.first == "dvm") // special case for the installation of dvm itself
		{
			(new DvmInstall).invoke(args);
			return;
		}
		
		install;
	}
	
private:
		
	void install ()
	{
		auto filename = buildFilename;
		auto url = buildUrl(filename);
		
		archivePath = Path.join(options.path.archives, filename);
		
		fetch(url, archivePath);		
		unpack;
		moveFiles;
		installWrapper;
		setPermissions;
		installEnvironment(createEnvironment);
		patchDmdConf;
	}
	
	void unpack ()
	{
		tmpCompilerPath = Path.join(options.path.tmp, "dmd-" ~ args.first);
		verbose("unpacking:");
		verbose(options.indentation, "source :", archivePath);
		verbose(options.indentation, "destination: ", tmpCompilerPath, '\n');
		extractArchive(archivePath, tmpCompilerPath);
	}
	
	void moveFiles ()
	{
		auto dmd = args.first.length > 0 && args.first[0] == '2' ? "dmd2" : "dmd";
		auto root = Path.join(tmpCompilerPath, dmd);
		auto platformRoot = Path.join(root, platform);
		
		if (!Path.exists(platformRoot))
			throw new DvmException(format(`The platform "{}" is not compatible with the compiler dmd {}`, platform, args.first), __FILE__, __LINE__);
		
		auto binSource = Path.join(platformRoot, options.path.bin);
		auto binDest = Path.join(installPath, options.path.bin);
		
		auto libSource = Path.join(platformRoot, options.path.lib);
		auto libDest = Path.join(installPath, options.path.lib);
		
		auto srcSource = Path.join(root, options.path.src);
		auto srcDest = Path.join(installPath, options.path.src);

		verbose("moving:");
		
		move(binSource, binDest);
		move(libSource, libDest);
		move(srcSource, srcDest);
	}
	
	void installWrapper ()
	{
		wrapper.target = Path.join(installPath, options.path.bin, "dmd");
		wrapper.path = Path.join(options.path.dvm, options.path.bin, "dmd-") ~ args.first;
		
		verbose("installing wrapper: " ~ wrapper.path);
		wrapper.write;
	}
	
	void setPermissions ()
	{
		verbose("setting permissions:");
		
		permission(Path.join(installPath, options.path.bin, "dmd"), "+x");
		permission(Path.join(installPath, options.path.bin, "dumpobj"), "+x");
		permission(Path.join(installPath, options.path.bin, "obj2asm"), "+x");
		permission(wrapper.path, "+x");
	}
	
	void installEnvironment (ShellScript sh)
	{
		sh.path = options.path.env;				
		Path.createPath(sh.path);
		sh.path = Path.join(sh.path, "dmd-" ~ args.first);
		
		verbose("installing environment: ", sh.path);
		sh.write;
	}
	
	ShellScript createEnvironment ()
	{		
		auto sh = new ShellScript;
		sh.echoOff;
		
		auto envPath = Path.join(installPath, options.path.bin);
		auto binPath = Path.join(options.path.dvm, options.path.bin);
		
		sh.exportPath("PATH", envPath, binPath, Sh.variable("PATH", false));
		
		return sh;
	}
	
	void patchDmdConf ()
	{			
		auto dmdConfPath = Path.join(installPath, options.path.conf);
		
		verbose("Patching: ", dmdConfPath);
		
		auto content = cast(string) File.get(dmdConfPath);
		content = content.substitute("-I%@P%/../../src/phobos", "-I%@P%/../src/phobos");
		
		File.set(dmdConfPath, content);
	}
	
	void move (string source, string destination)
	{
		verbose(options.indentation, "source: ", source);
		verbose(options.indentation, "destination: ", destination, '\n');		
		
		if (Path.exists(destination))
			Path.remove(destination, true);

		Path.createPath(destination);	
		Path.rename(source, destination);
	}
	
	string installPath ()
	{
		if (installPath_.length > 0)
			return installPath_;

		return installPath_ = Path.join(options.path.compilers, "dmd-" ~ args.first);
	}
	
	void permission (string path, string mode)
	{
		verbose(options.indentation, "mode: " ~ mode);
		verbose(options.indentation, "file: " ~ path, '\n');
		
		Path.permission(path, mode);
	}
}