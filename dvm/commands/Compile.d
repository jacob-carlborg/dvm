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
			string origMakefile       = "win32.mak";
			string secondaryMakefile  = "win32.mak";
			string patchedDMDMakefile = "win32-fixed.mak";
		}

		else
		{
			string origMakefile       = "posix.mak";
			string secondaryMakefile  = options.platform ~ ".mak";
			string patchedDMDMakefile = "posix.mak";
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

		string dmdMakefile;
		string druntimeMakefile;
		string phobosMakefile;
	}
	
	this ()
	{
		super("compile", "Compiles DMD and standard library.");
	}
	
	void execute ()
	{
		compile("", options.compileDebug);
	}
	
protected:
	
	void compile (string directory="", bool compileDebug=false)
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
		
		compileDMD(compileDebug);
		
		// Temporarily add the new dmd to PATH
		auto savePath = Environment.get("PATH");
		Environment.set("PATH", installBin ~ options.path.pathSeparator ~ savePath);
		scope(exit) Environment.set("PATH", savePath);
		
		compileDruntime;
		compilePhobos(compileDebug);
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
			installPath  = Path.join(base, options.platform);
		}
		
		dmdPath      = Environment.toAbsolute(dmdPath);
		druntimePath = Environment.toAbsolute(druntimePath);
		phobosPath   = Environment.toAbsolute(phobosPath);
		installPath  = Environment.toAbsolute(installPath);

		installBin   = Path.join(installPath, binName);
		installLib   = Path.join(installPath, libName);
		
		dmdMakefile      = Path.exists(Path.join(dmdPath,      origMakefile))? origMakefile : secondaryMakefile;
		druntimeMakefile = Path.exists(Path.join(druntimePath, origMakefile))? origMakefile : secondaryMakefile;
		phobosMakefile   = Path.exists(Path.join(phobosPath,   origMakefile))? origMakefile : secondaryMakefile;

		version (Posix)
			patchedDMDMakefile = dmdMakefile;

		version (Windows)
			phobosLibName = "phobos";

		else
			phobosLibName = "libphobos2";

		phobosLibName = phobosLibName ~ options.path.libExtension;
	}
	
	void verifyStructure ()
	{
		bool valid = true;
		
		if(!Path.exists(Path.join(dmdPath, dmdMakefile)))
			valid = false;
		
		if(!Path.exists(Path.join(druntimePath, druntimeMakefile)))
			valid = false;
		
		if(!Path.exists(Path.join(phobosPath, phobosMakefile)))
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

		latestDMDLib = Path.join(latestDMDPath, "lib");
		latestDMDBin = Path.join(latestDMDPath, "bin");
		
		if(!Path.exists(latestDMDPath))
		{
			auto install = new Install();
			install.install(ver);
		}
	}

	void compileDMD (bool compileDebug)
	{
		Environment.cwd = dmdPath;
		
		string targetName;
		version (Windows)
			targetName = compileDebug? "debdmd" : "release";

		version (Windows)
			patchDMDMake;

		// Build dmd executable
		verbose("Building DMD: ", dmdPath);
		auto result = system("make -f" ~ patchedDMDMakefile ~ " " ~ targetName);
		
		if(result.status != 0)
			throw new DvmException("Error building DMD's executable", __FILE__, __LINE__);
		
		auto dmdExeName = "dmd" ~ options.path.executableExtension;

		// Copy dmd executable
		Path.copy(Path.join(dmdPath, dmdExeName), Path.join(installBin, dmdExeName));
		
		// Set executable permissions
		version (Posix)
		{
			Path.permission(Path.join(dmdPath, dmdExeName), "+x");
			Path.permission(Path.join(installBin, dmdExeName), "+x");
		}

		// Copy needed files from lib/bin directories
		if(isGitStructure)
		{
			verbose("Copying lib/bin directories: ");

			auto fileSets = ["lib"[]: Path.children(latestDMDLib), "bin": Path.children(latestDMDBin)];
			
			foreach (srcSubDir, fileSet; fileSets)
			foreach (info; fileSet)
			if(!info.folder)
			if(info.name != dmdExeName && info.name != phobosLibName)
			{
				auto targetSubDir = srcSubDir ~ bitsLabel;

				auto sourcePath = Path.join(latestDMDPath, srcSubDir, info.name);
				auto targetPath = Path.join(installPath, targetSubDir, info.name);
				
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
		auto result = system("make -f" ~ druntimeMakefile);

		if(result.status != 0)
			throw new DvmException("Error building druntime", __FILE__, __LINE__);
	}
	
	void compilePhobos (bool compileDebug)
	{
		verbose("Building phobos: ", phobosPath);

		string targetName;
		version (Posix)
			targetName = compileDebug? "debug" : "release";

		Environment.cwd = phobosPath;
		auto result = system("make -f" ~ phobosMakefile ~ " " ~ targetName ~ " " ~ quote("DRUNTIME="~druntimePath));
		
		if(result.status != 0)
			throw new DvmException("Error building phobos", __FILE__, __LINE__);

		// Copy phobos lib
		auto sourcePath = phobosPath;

		version (Posix)
			sourcePath = Path.join(sourcePath, "generated", options.platform, targetName, bitsLabel);

		sourcePath = Path.join(sourcePath, phobosLibName);
		
		auto targetPath = Path.join(installLib, phobosLibName);

		Path.copy(sourcePath, targetPath);
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
		auto srcPath  = Path.join(dmdPath, dmdMakefile);
		auto destPath = Path.join(dmdPath, patchedDMDMakefile);

		verbose("Patching:");
		verbose(options.indentation, "source: ", srcPath);
		verbose(options.indentation, "destination: ", destPath, '\n');		
		
		auto content = cast(string) File.get(srcPath);

		content = content.substitute(`CC=\dm\bin\dmc`, `CC=dmc`);
		content = content.substitute(dmdMakefile, patchedDMDMakefile);

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