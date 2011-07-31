/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: July 26, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Compile;

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
import dvm.commands.Fetch;
import dvm.commands.Install;
import dvm.commands.Use;
import dvm.core._;
import dvm.dvm.Wrapper;
import dvm.dvm._;
import Path = dvm.io.Path;
import dvm.sys.Process;
import dvm.util.Util;
import dvm.util.Version;

//TODO: Be more flexible with lib/lib32/lib64 and bin/etc...?
//TODO: Make sure to support compiling older DMDs (at least release-style).
//TODO: Auto-install DMC if not available in PATH.
//TODO: Make it compile DMD1.
//TODO: Option to choose release/debug build.
//TODO: Build rdmd if available.

class Compile : Fetch
{	
	private
	{
		static if (Windows)
		{
			const origMakefile    = "win32.mak";
			const patchedMakefile = "win32-fixed.mak";
		}

		else
		{
			const origMakefile    = "posix.mak";
			const patchedMakefile = "posix.mak";
		}

		bool isGitStructure;
		
		string base;
		string dmdPath;
		string druntimePath;
		string phobosPath;
		
		string installPath;
		string installBin;
		string installLib;
		
		string latestDMDPath;
		string latestDMDBin;
		string latestDMDLib;

		string phobosLibName;
	}
	
	this ()
	{
		super("compile", "Compiles DMD and standard library.");
	}
	
	void execute ()
	{
		compile();
	}
	
protected:
	
	void compile (string directory="")
	{
		if(directory == "")
		{
			if (args.any())
				directory = args.first;
			
			else
				directory = ".";
		}

		base = Path.normalize(directory);
		analyzeStructure;
		verifyStructure;

		verbose("Project structure: ", isGitStructure? "Git-style" : "Release-style");
		
		if (isGitStructure)
			installLatestDMD; // Need this for sc.ini/dmd.conf and packaged static libs
		
		// Save current dir
		auto saveCwd = Environment.cwd;
		scope(exit) Environment.cwd = saveCwd;
		
		compileDMD;
		
		// Temporarily add the new dmd to PATH
		auto savePath = Environment.get("PATH");
		Environment.set("PATH", installBin ~ options.path.pathSeparator ~ savePath);
		scope(exit) Environment.set("PATH", savePath);
		
		compileDruntime;
		compilePhobos;
	}

private:

	void analyzeStructure ()
	{
		auto gitDMDPath      = Path.join(base, "dmd", "src");
		auto gitDruntimePath = Path.join(base, "druntime");
		auto gitPhobosPath   = Path.join(base, "phobos");
		
		if (Path.exists(gitDMDPath) && Path.exists(gitDruntimePath) && Path.exists(gitPhobosPath))
		{
			isGitStructure = true;
			dmdPath      = gitDMDPath;
			druntimePath = gitDruntimePath;
			phobosPath   = gitPhobosPath;
			installPath  = Path.join(base, "dmd");
		}
		else
		{
			isGitStructure = false;
			dmdPath      = Path.join(base, "src", "dmd");
			druntimePath = Path.join(base, "src", "druntime");
			phobosPath   = Path.join(base, "src", "phobos");
			installPath  = Path.join(base, Options.platform);
		}
		
		dmdPath      = Environment.toAbsolute(dmdPath);
		druntimePath = Environment.toAbsolute(druntimePath);
		phobosPath   = Environment.toAbsolute(phobosPath);
		installPath  = Environment.toAbsolute(installPath);

		installBin   = Path.join(installPath, binName);
		installLib   = Path.join(installPath, libName);
		
		phobosLibName = "phobos" ~ options.path.libExtension;
	}
	
	void verifyStructure ()
	{
		bool valid = true;
		
		if(!Path.exists(Path.join(dmdPath, origMakefile)))
			valid = false;
		
		if(!Path.exists(Path.join(druntimePath, origMakefile)))
			valid = false;
		
		if(!Path.exists(Path.join(phobosPath, origMakefile)))
			valid = false;
		
		if (!valid)
		{
			throw new DvmException(
				"Unexpected DMD project structure in '"~base~"'\n\n"~
				"Make sure the path you give (or the current path) is either the\n"~
				"top-level of an extracted DMD release or a directory containing\n"~
				"Git checkouts of dmd, druntime, and phobos.",
			__FILE__, __LINE__);
		}
	}
	
	void installLatestDMD ()
	{
		// Only install if missing
		auto ver = "2." ~ getLatestDMDVersion("2");
		latestDMDPath = Path.join(options.path.compilers, "dmd-" ~ ver);

		latestDMDLib = Path.join(latestDMDPath, libName);
		latestDMDBin = Path.join(latestDMDPath, binName);
		
		if(!Path.exists(latestDMDPath))
		{
			auto install = new Install();
			install.install(ver);
		}
	}

	void compileDMD ()
	{
		Environment.cwd = dmdPath;
		
		version (Windows)
			patchDMDMake;

		// Build dmd executable
		verbose("Building DMD: ", dmdPath);
		auto result = system("make -f" ~ patchedMakefile);
		
		if(result.status != 0)
			throw new DvmException("Error building DMD's executable", __FILE__, __LINE__);
		
		// Copy dmd executable
		auto dmdExeName = "dmd" ~ options.path.executableExtension;
		Path.copy(Path.join(dmdPath, dmdExeName), Path.join(installBin, dmdExeName));
		
		// Copy needed files from lib/bin directories
		if(isGitStructure)
		{
			verbose("Copying lib/bin directories: ");

			auto fileSets = [libName(): Path.children(latestDMDLib), binName(): Path.children(latestDMDBin)];
			
			foreach (subDirName, fileSet; fileSets)
			foreach (info; fileSet)
			if(!info.folder)
			if(info.name != dmdExeName && info.name != phobosLibName)
			{
				auto sourcePath = Path.join(latestDMDPath, subDirName, info.name);
				auto targetPath = Path.join(installPath, subDirName, info.name);
				
				if(!Path.exists(targetPath))
					Path.copy(sourcePath, targetPath);
			}
			
			patchDmdConf();
		}
	}
	
	void compileDruntime ()
	{
		verbose("Building druntime: ", druntimePath);

		Environment.cwd = druntimePath;
		auto result = system("make -f" ~ origMakefile);

		if(result.status != 0)
			throw new DvmException("Error building druntime", __FILE__, __LINE__);
	}
	
	void compilePhobos ()
	{
		verbose("Building phobos: ", phobosPath);

		Environment.cwd = phobosPath;
		auto result = system("make -f" ~ origMakefile ~ " " ~ quote("DRUNTIME="~druntimePath));
		
		if(result.status != 0)
			throw new DvmException("Error building phobos", __FILE__, __LINE__);

		Path.copy(Path.join(phobosPath, phobosLibName), Path.join(installLib, phobosLibName));
	}
	
	void patchDmdConf ()
	{
		auto patchedFile = Path.join(installBin, options.path.confName);
		verbose("Patching: ", patchedFile);
		
		auto content = cast(string) File.get(patchedFile);
		
		auto newPath = isGitStructure? "%@P%/../.." : "%@P%/../../src";
		content = content.slashSafeSubstitute("%@P%/../src", newPath);
		content = content.slashSafeSubstitute("%@P%/../lib", "%@P%/../"~libName);
		
		File.set(patchedFile, content);
	}
	
	void patchDMDMake ()
	{
		auto srcPath  = Path.join(dmdPath, origMakefile);
		auto destPath = Path.join(dmdPath, patchedMakefile);

		verbose("Patching:");
		verbose(options.indentation, "source: ", srcPath);
		verbose(options.indentation, "destination: ", destPath, '\n');		
		
		auto content = cast(string) File.get(srcPath);

		content = content.substitute(`CC=\dm\bin\dmc`, `CC=dmc`);
		content = content.substitute(origMakefile, patchedMakefile);

		File.set(destPath, content);
	}
	
	string binName ()
	{
		return "bin" ~ bitsLabel;
	}

	string libName ()
	{
		return "lib" ~ bitsLabel;
	}

	string bitsLabel ()
	{
		version(Windows)
			return "";
		
		version(OSX)
			return "";
		
		return options.is64bit? "64" : "32";
	}
	
	string quote(string str)
	{
		version (Windows)
			return format(`"{}"`, str);
		
		else
			return format(`'{}'`, str);
	}
}