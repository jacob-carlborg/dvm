/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Install;

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

import dvm.commands.Command;
import dvm.commands.DmcInstall;
import dvm.commands.DvmInstall;
import dvm.commands.Fetch;
import dvm.commands.Use;
import mambo.core._;
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
		string ver;
	}
	
	this ()
	{
		super("install", "Install one or many D versions.");
	}
	
	void execute ()
	{
		// special case for the installation of dvm itself or dmc
		if (args.any() && (args.first == "dvm" || args.first == "dmc"))
		{
			if (args.first == "dvm")
				(new DvmInstall).invoke(args);
			
			else
				(new DmcInstall).invoke(args);
				
			return;
		}
		
		install;
	}
	
	void install (string ver = "")
	{
		if(ver == "")
			ver = getDMDVersion();

		this.ver = ver;
		
		auto filename = buildFilename(ver);
		auto url = buildUrl(filename);
		
		archivePath = Path.join(options.path.archives, filename);

		fetch(url, archivePath);		
		println("Installing: dmd-", ver);

		unpack;
		moveFiles;
		installWrapper;

		version (Posix)
			setPermissions;

		installEnvironment(createEnvironment);
		patchDmdConf;
		
		if (options.tango)
			installTango;
	}
	
private:

	void unpack ()
	{
		tmpCompilerPath = Path.join(options.path.tmp, "dmd-" ~ ver);
		verbose("Unpacking:");
		verbose(options.indentation, "source: ", archivePath);
		verbose(options.indentation, "destination: ", tmpCompilerPath, '\n');
		extractArchive(archivePath, tmpCompilerPath);
	}
	
	void moveFiles ()
	{
		auto dmd = ver.length > 0 && ver[0] == '2' ? "dmd2" : "dmd";
		auto root = Path.join(tmpCompilerPath, dmd);
		auto platformRoot = Path.join(root, Options.platform);
		
		if (!Path.exists(platformRoot))
			throw new DvmException(format(`The platform "{}" is not compatible with the compiler dmd {}`, Options.platform, ver), __FILE__, __LINE__);
		
		auto binSource = getBinSource(platformRoot);
		auto binDest = Path.join(installPath, options.path.bin);		
	 
		auto libSource = getLibSource(platformRoot);
		auto libDest = Path.join(installPath, options.path.lib);

		auto srcSource = Path.join(root, options.path.src);
		auto srcDest = Path.join(installPath, options.path.src);

		verbose("Moving:");
		
		Path.move(binSource, binDest);
		Path.move(libSource, libDest);
		Path.move(srcSource, srcDest);
	}

	void installWrapper ()
	{
		wrapper.target = Path.join(installPath, options.path.bin, "dmd" ~ options.path.executableExtension);
		wrapper.path = Path.join(options.path.dvm, options.path.bin, "dmd-") ~ ver;

		version (Windows)
			wrapper.path ~= ".bat";
		
		verbose("Installing wrapper: " ~ wrapper.path);
		wrapper.write;
	}
	
	void setPermissions ()
	{
		verbose("Setting permissions:");
		auto binPath = Path.join(installPath, options.path.bin);

		setExecutableIfExists(Path.join(binPath, "ddemangle"));
		setExecutableIfExists(Path.join(binPath, "dman"));
		setExecutableIfExists(Path.join(binPath, "dmd"));
		setExecutableIfExists(Path.join(binPath, "dumpobj"));
		setExecutableIfExists(Path.join(binPath, "obj2asm"));
		setExecutableIfExists(Path.join(binPath, "rdmd"));
		setExecutableIfExists(Path.join(binPath, "shell"));

		setExecutableIfExists(wrapper.path);
	}
	
	void installEnvironment (ShellScript sh)
	{
		sh.path = options.path.env;
		Path.createPath(sh.path);
		sh.path = Path.join(sh.path, "dmd-" ~ ver ~ options.path.scriptExtension);
		
		verbose("Installing environment: ", sh.path);
		sh.write;
	}
	
	ShellScript createEnvironment ()
	{		
		auto sh = new ShellScript;
		sh.echoOff;
		
		auto envPath = Path.join(installPath, options.path.bin);
		auto binPath = Path.join(options.path.dvm, options.path.bin);
		
		version (Posix)
			sh.exportPath("PATH", envPath, binPath, Sh.variable("PATH", false));
		
		version (Windows)
		{
			Path.native(envPath);
			Path.native(binPath);
			sh.exportPath("DVM",  envPath, binPath).nl;
			sh.exportPath("PATH", envPath, Sh.variable("PATH", false));
		}
		
		return sh;
	}
	
	void patchDmdConf (bool tango = false)
	{
		auto dmdConfPath = Path.join(installPath, options.path.conf);
		
		verbose("Patching: ", dmdConfPath);
		
		auto src = tango ? "-I%@P%/../import -defaultlib=tango -debuglib=tango -version=Tango" : "-I%@P%/../src/phobos";
		auto content = cast(string) File.get(dmdConfPath);
		
		content = content.slashSafeSubstitute("-I%@P%/../../src/phobos", src);
		content = content.slashSafeSubstitute("-I%@P%/../../src/druntime/import", "-I%@P%/../src/druntime/import");
		content = content.slashSafeSubstitute("-L-L%@P%/../lib32", "-L-L%@P%/../lib");
		
		File.set(dmdConfPath, content);
	}
	
	void installTango ()
	{
		verbose("Installing Tango");

		fetchTango;
		unpackTango;
		setupTangoEnvironment;
		buildTango;
		moveTangoFiles;
		patchDmdConfForTango;
	}
	
	void fetchTango ()
	{
		const tangoUrl = "http://dsource.org/projects/tango/changeset/head/trunk?old_path=%2F&format=zip";
		fetch(tangoUrl, options.path.tangoZip);
	}
	
	void unpackTango ()
	{
		verbose("Unpacking:");
		verbose(options.indentation, "source: ", options.path.tangoZip);
		verbose(options.indentation, "destination: ", options.path.tangoTmp, '\n');
		extractArchive(options.path.tangoZip, options.path.tangoUnarchived);
	}
	
	void setupTangoEnvironment ()
	{
		verbose(format(`Installing "{}" as the temporary D compiler`, ver));
		auto path = Environment.get("PATH");
		path = Path.join(installPath, options.path.bin) ~ options.path.pathSeparator ~ path;
		Environment.set("PATH", path);
	}

	void buildTango ()
	{
		version (Posix)
		{
			verbose("Setting permission:");
			permission(options.path.tangoBob, "+x");
		}
		
		verbose("Building Tango...");

		string[] tangoBuildOptions = ["-r=dmd"[], "-c=dmd", "-u", "-q", "-l=" ~ options.path.tangoLibName];

		version (Posix)
			tangoBuildOptions ~= options.is64bit ? "-m=64" : "-m=32";

		auto process = new Process(true, options.path.tangoBob ~ tangoBuildOptions ~ "."[]);
		process.workDir = options.path.tangoTmp;
		process.execute;
		
		auto result = process.wait;

		if (options.verbose || result.reason != Process.Result.Exit)
		{
			println("Output of the Tango build:", "\n");
			Stdout.copy(process.stdout).flush;
			println();
			println("Process ", process.programName, '(', process.pid, ')', " exited with:");
			println(options.indentation, "reason: ", result);
			println(options.indentation, "status: ", result.status, "\n");
		}
	}
	
	void moveTangoFiles ()
	{
		verbose("Moving:");
		
		auto importDest = Path.join(installPath, options.path.import_);
		
		auto tangoSource = options.path.tangoSrc;
		auto tangoDest = Path.join(importDest, "tango");
		
		
		auto objectSrc = options.path.tangoObject;
		auto objectDest = Path.join(importDest, options.path.object_di);
		
		auto vendorSrc = options.path.tangoVendor;
		auto vendorDest = Path.join(importDest, options.path.std);
		
		Path.move(options.path.tangoLib, Path.join(installPath, options.path.lib, options.path.tangoLibName ~ options.path.libExtension));
		Path.move(vendorSrc, vendorDest);
		Path.move(tangoSource, tangoDest);
		Path.move(objectSrc, objectDest);
	}
	
	void patchDmdConfForTango ()
	{
		auto dmdConfPath = Path.join(installPath, options.path.conf);
		
		verbose("Patching: ", dmdConfPath);
		
		string newInclude = "-I%@P%/../import";
		string newArgs = " -defaultlib=tango -debuglib=tango -version=Tango";
		string content = cast(string) File.get(dmdConfPath);
		
		string oldInclude1 = "-I%@P%/../src/phobos";
		string oldInclude2 = "-I%@P%/../../src/druntime/import";
		version (Windows)
		{
			oldInclude1 = '"' ~ oldInclude1 ~ '"';
			oldInclude2 = '"' ~ oldInclude2 ~ '"';
			newInclude  = '"' ~ newInclude  ~ '"';
		}

		auto src = newInclude ~ newArgs;
		
		content = content.slashSafeSubstitute(oldInclude1, src);
		content = content.slashSafeSubstitute(oldInclude2, "");
		
		File.set(dmdConfPath, content);
	}
	
	string installPath ()
	{
		if (installPath_.length > 0)
			return installPath_;

		return installPath_ = Path.join(options.path.compilers, "dmd-" ~ ver);
	}
	
	void permission (string path, string mode)
	{
		version (Posix)
		{
			verbose(options.indentation, "mode: " ~ mode);
			verbose(options.indentation, "file: " ~ path, '\n');
			
			Path.permission(path, mode);
		}
	}
	
	string getLibSource (string platformRoot)
	{
		string libPath = Path.join(platformRoot, options.path.lib);
		
		if (Path.exists(libPath))
			return libPath;
		
		if (options.is64bit)
		{
			libPath = Path.join(platformRoot, options.path.lib64);
			
			if (Path.exists(libPath))
				return libPath;
			
			else
				throw new DvmException("There is no 64bit compiler available on this platform", __FILE__, __LINE__);
		}

		libPath = Path.join(platformRoot, options.path.lib32);

		if (Path.exists(libPath))
			return libPath;

		throw new DvmException("Could not find the library path: " ~ libPath, __FILE__, __LINE__);
	}

	string getBinSource (string platformRoot)
    {
    	string binPath = Path.join(platformRoot, options.path.bin);

    	if (Path.exists(binPath))
    		return binPath;

    	if (options.is64bit)
    	{
    		binPath = Path.join(platformRoot, options.path.bin64);

    		if (Path.exists(binPath))
    			return binPath;

    		else
    			throw new DvmException("There is no 64bit compiler available on this platform", __FILE__, __LINE__);
    	}

    	binPath = Path.join(platformRoot, options.path.bin32);

    	if (Path.exists(binPath))
    		return binPath;

    	throw new DvmException("Could not find the binrary path: " ~ binPath, __FILE__, __LINE__);
	}

	void setExecutableIfExists (string path)
	{
		if (Path.exists(path))
			permission(path, "+x");
	}

	void validateArguments (string errorMessage = null)
	{
		if (errorMessage.empty())
			errorMessage = "Cannot install a compiler without specifying a version";

		super.validateArguments(errorMessage);
	}
}