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
import dvm.commands.DmcInstall;
import dvm.commands.Fetch;
import dvm.commands.Install;
import dvm.commands.Use;
import mambo.core._;
import dvm.dvm.Wrapper;
import dvm.dvm._;
import Path = dvm.io.Path;
import dvm.sys.Process;
import dvm.util.Util;
import dvm.util.Version;

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
		bool isD1;
		
		string base;
		string dmdBase;
		string dmdPath;
		string druntimePath;
		string phobosPath;
		string toolsPath;
		
		string installBinName;
		string installLibName;

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
		if (directory == "")
		{
			if (args.any())
				directory = args.first;
			
			else
				directory = ".";
		}

		base = Path.normalize(directory);
		if (base == "")
			base = ".";
		
		analyzeStructure;
		verifyStructure;

		verbose("Project structure: ", isGitStructure? "Git-style" : "Release-style");
		
		version (Windows)
			installDMC();
		
		if (isGitStructure)
			installLatestDMD; // Need this for sc.ini/dmd.conf and packaged static libs
		
		// Save current dir
		auto saveCwd = Environment.cwd;
		scope(exit) Environment.cwd = saveCwd;

		// Save PATH
		auto savePath = Environment.get("PATH");
		scope(exit) Environment.set("PATH", savePath);

		version (Windows)
		{
			// Using the dmc.bat wrapper to compile DMD results in a mysterious 
			// "paths with spaces" heisenbug that I can't seem to track down.
			if (Path.exists(Path.join(options.path.compilers, "dmc")))
			{
				auto dmcPath = Path.join(options.path.compilers, "dmc", "bin");
				addEnvPath(dmcPath);
			}
		}

		compileDMD(compileDebug);
		
		// Add the new dmd to PATH
		addEnvPath(installBin);
		
		compileDruntime;
		compilePhobos(compileDebug);
		compileRDMD(compileDebug);
	}

private:

	void analyzeStructure ()
	{
		auto gitDMDPath      = Path.join(base, "dmd", "src");
		auto gitDruntimePath = Path.join(base, "druntime");
		auto gitPhobosPath   = Path.join(base, "phobos");
		auto gitToolsPath    = Path.join(base, "tools");
		
		if (Path.exists(gitDMDPath) && Path.exists(gitPhobosPath))
		{
			isGitStructure = true;
			dmdBase      = Path.join(base, "dmd");
			dmdPath      = gitDMDPath;
			druntimePath = gitDruntimePath;
			phobosPath   = gitPhobosPath;
			toolsPath    = gitToolsPath;
			installPath  = dmdBase;
		}
		else
		{
			isGitStructure = false;
			dmdBase      = base;
			dmdPath      = Path.join(base, "src", "dmd");
			druntimePath = Path.join(base, "src", "druntime");
			phobosPath   = Path.join(base, "src", "phobos");
			//toolsPath    = ; // N/A: Releases don't include 'rdmd.d'
			installPath  = Path.join(base, options.platform);
		}
		
		dmdBase      = Environment.toAbsolute(dmdBase);
		dmdPath      = Environment.toAbsolute(dmdPath);
		druntimePath = Environment.toAbsolute(druntimePath);
		phobosPath   = Environment.toAbsolute(phobosPath);
		toolsPath    = Environment.toAbsolute(toolsPath);
		installPath  = Environment.toAbsolute(installPath);
		
		installBinName = firstExisting(["bin"[], "bin"~bitsLabel], installPath, null, "bin"~bitsLabel);
		installLibName = firstExisting(["lib"[], "lib"~bitsLabel], installPath, null, "lib"~bitsLabel);
		
		installBin = Path.join(installPath, installBinName);
		installLib = Path.join(installPath, installLibName);
		
		dmdMakefile      = Path.exists(Path.join(dmdPath,      origMakefile))? origMakefile : secondaryMakefile;
		druntimeMakefile = Path.exists(Path.join(druntimePath, origMakefile))? origMakefile : secondaryMakefile;
		phobosMakefile   = Path.exists(Path.join(phobosPath,   origMakefile))? origMakefile : secondaryMakefile;

		isD1 = !Path.exists(druntimePath);

		version (Posix)
			patchedDMDMakefile = dmdMakefile;

		version (Windows)
			phobosLibName = "phobos";

		else
			phobosLibName = isD1? "libphobos" : "libphobos2";

		phobosLibName = phobosLibName ~ options.path.libExtension;
	}
	
	void verifyStructure ()
	{
		bool valid = true;
		
		if (!Path.exists(Path.join(dmdPath, dmdMakefile)))
			valid = false;
		
		if (!isD1 && !Path.exists(Path.join(druntimePath, druntimeMakefile)))
			valid = false;
		
		if (!Path.exists(Path.join(phobosPath, phobosMakefile)))
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
	
	version (Windows)
		void installDMC ()
		{
			// Only install if not on PATH
			auto path = Environment.exePath("dmc.exe");
			if(path)
				return;
			
			path = Environment.exePath("dmc.bat");
			if(path)
				return;
			
			auto dmcInstall = new DmcInstall();
			dmcInstall.execute();
		}
	
	void installLatestDMD ()
	{
		// Only install if missing
		auto ver = "2." ~ getLatestDMDVersion("2");
		latestDMDPath = Path.join(options.path.compilers, "dmd-" ~ ver);

		latestDMDLib = Path.join(latestDMDPath, "lib");
		latestDMDBin = Path.join(latestDMDPath, "bin");
		
		if (!Path.exists(latestDMDPath))
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
		
		if (result.status != 0)
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
		if (isGitStructure)
		{
			verbose("Copying lib/bin directories: ");
			
			auto fileSets = ["lib"[]: Path.children(latestDMDLib), "bin": Path.children(latestDMDBin)];
			
			foreach (srcSubDir, fileSet; fileSets)
			foreach (info; fileSet)
			if (!info.folder)
			if (info.name != dmdExeName && info.name != phobosLibName)
			{
				auto targetSubDir = srcSubDir ~ bitsLabel;
				
				auto sourcePath = Path.join(latestDMDPath, srcSubDir, info.name);
				auto targetPath = Path.join(installPath, targetSubDir, info.name);
				
				if (!Path.exists(targetPath))
					Path.copy(sourcePath, targetPath);
					
				else if (info.name == options.path.confName)
				{
					Path.copy(targetPath, targetPath ~ ".dvm-bak");
					Path.copy(sourcePath, targetPath);
				}
			}
			
			patchDmdConf();
		}
	}
	
	void compileDruntime ()
	{
		if (isD1)
			return;
		
		verbose("Building druntime: ", druntimePath);

		Environment.cwd = druntimePath;
		auto result = system("make -f" ~ druntimeMakefile);

		if (result.status != 0)
			throw new DvmException("Error building druntime", __FILE__, __LINE__);
	}
	
	void compilePhobos (bool compileDebug)
	{
		verbose("Building phobos: ", phobosPath);
		
		// Rebuilding minit.obj should never be necessary, and doing so requires
		// an assembler not included in DMC, so force it to never be rebuilt.
		version (Windows)
		{
			auto minitSearchPaths = [phobosPath, druntimePath, Path.join(druntimePath, "src", "rt")];
			auto minitPath = firstExisting(minitSearchPaths, null, "minit.obj");
			touch(Path.join(minitPath, "minit.obj"));
		}

		string targetName;
		version (Posix)
		{
			if (!isD1)
				targetName = compileDebug? "debug" : "release";
		}
		
		string dirDef;
		string dmdDef;
		version (Windows)
		{
			if (isD1)
			{
				dirDef = " " ~ quote("DIR=" ~ dmdBase);
				dmdDef = " " ~ quote("DMD=" ~ installBin ~ `\dmd`);
			}
		}
		
		auto druntimeDef = " " ~ quote("DRUNTIME="~druntimePath);
		
		Environment.cwd = phobosPath;
		auto result = system("make -f" ~ phobosMakefile ~ " " ~ targetName ~ druntimeDef ~ dirDef ~ dmdDef);
		
		if (result.status != 0)
			throw new DvmException("Error building phobos", __FILE__, __LINE__);

		// Find phobos lib
		auto generatedDir = Path.join(phobosPath, "generated", options.platform, targetName);
		auto generatedBitsDir = Path.join(generatedDir, bitsLabel);
		auto searchPaths = [generatedDir, generatedBitsDir, Path.join(phobosPath, "lib"), Path.join(phobosPath, "lib"~bitsLabel), phobosPath];
		auto sourcePath = firstExisting(searchPaths, null, phobosLibName);
		sourcePath = Path.join(sourcePath, phobosLibName);
		
		// Copy phobos lib
		auto targetPath = Path.join(installLib, phobosLibName);
		Path.copy(sourcePath, targetPath);
	}
	
	void compileRDMD (bool compileDebug)
	{
		auto rdmdSrc = Path.join(toolsPath, "rdmd.d");
		if (!isGitStructure || !Path.exists(rdmdSrc))
			return;
		
		verbose("Building RDMD: ", rdmdSrc);

		Environment.cwd = toolsPath;
		auto args = compileDebug? "-debug -gc" : "-release -inline -O";
		auto result = system("dmd rdmd.d -wi " ~ args);
		
		if (result.status != 0)
			throw new DvmException("Error building RDMD", __FILE__, __LINE__);

		auto rdmdExeName = "rdmd" ~ options.path.executableExtension;
		Path.copy(Path.join(toolsPath, rdmdExeName), Path.join(installBin, rdmdExeName));
	}
	
	void patchDmdConf ()
	{
		auto patchedFile = Path.join(installBin, options.path.confName);
		verbose("Patching: ", patchedFile);
		
		auto content = cast(string) File.get(patchedFile);
		
		auto newPath = isGitStructure? "%@P%/../.." : "%@P%/../../src";
		content = content.slashSafeSubstitute("%@P%/../src", newPath);
		content = content.slashSafeSubstitute("%@P%/../lib", "%@P%/../"~installLibName);
		content = content.slashSafeSubstitute("%@P%/../lib3264", "%@P%/../lib64");
		content = content.slashSafeSubstitute("%@P%/../lib6464", "%@P%/../lib64");
		
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
	
	string bitsLabel ()
	{
		return options.is64bit? "64" : "32";
	}
	
	string quote (string str)
	{
		version (Windows)
			return format(`"{}"`, str);
		
		else
			return format(`'{}'`, str);
	}
	
	void addEnvPath (string path)
	{
		Environment.set("PATH", path ~ options.path.pathSeparator ~ Environment.get("PATH"));
	}
	
	void touch(string filename)
	{
		// Merely opening the file for append and closing doesn't appear to work
		auto data = File.get(filename);
		File.set(filename, data);
	}
	
	// Returns the first element of paths for which 'pre/path/post' exists,
	// or defaultPath if none.
	string firstExisting(string[] paths, string pre = null, string post = null, string defaultPath = null)
	{
		foreach (string path; paths)
		{
			auto testPath = path;
			testPath = pre is null? testPath : Path.join(pre, testPath);
			testPath = post is null? testPath : Path.join(testPath, post);

			if (Path.exists(testPath))
				return path;
		}

		return defaultPath;
	}
}