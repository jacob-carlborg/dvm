/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Options;

import tango.io.Path;
import tango.sys.HomeFolder;

import dvm.core.string;
import dvm.util.Singleton;
import dvm.util.Version;

class Options
{
	mixin Singleton;
	
	const string indentation = "    ";
	const int numberOfIndentations = 1;
	const Path path = Path();
	
	bool verbose = false;
	bool tango = false;
	bool isDefault = false;

	version (D_LP64)
	    bool is64bit = true;

	else
	    bool is64bit = false;
}

private struct Path
{
	const bin = "bin";
    const bin32 = "bin32";
    const bin64 = "bin64";
	const src = "src";
	const lib = "lib";
	const lib32 = "lib32";
	const lib64 = "lib64";
	const import_ = "import";
	const license = "license.txt";
	const readme = "README.TXT";
	const std = "std";
	const object_di = "object.di";
	
	version (Posix)
	{
		const libExtension = ".a";
		const tangoLibName = "libtango";
		const pathSeparator = ":";
	}
	
	else
	{
		const libExtension = ".lib";
		const tangoLibName = "tango";
		const pathSeparator = ";";
	}
	
	private
	{
		string home_;
		string dvm_;
		string env_;
		string compilers_;
		string archives_;
		string result_;
		string tmp_;
		string scripts_;
		string dvmScript_;
		string dvmExecutable_;
		string conf_;
		string tangoZip_;
		string tangoTmp_;
		string tangoBob_;
		string tangoLib_;
		string tangoSrc_;
		string tangoObject_;
		string tangoVendor_;
		string tangoUnarchived_;
		string defaultEnv_;
		string defaultBin_;
		string config_;
		string installed_;
		
		version (Posix)
		{
			const dvmDir = ".dvm";
			const string scriptExtension = "";
			const string executableExtension = "";
			const string confExtension = ".conf";
			
		}

		else version (Windows)
		{
			const dvmDir = "dvm";
			const scriptExtension = ".bat";
			const executableExtension = ".exe";
			const confExtension = ".ini";
		}
	}
	
	string home ()
	{
		if (home_.length > 0)
			return home_;

		return home_ = homeFolder;
	}

	string dvm ()
	{
		if (dvm_.length > 0)
			return dvm_;

		return dvm_ = join(home, dvmDir);
	}
	
	string dvmExecutable ()
	{
		if (dvmExecutable_.length > 0)
			return dvmExecutable_;
		
		return dvmExecutable_ = join(dvm, bin, "dvm" ~ executableExtension);
	}
	
	string dvmScript ()
	{
		if (dvmScript_.length > 0)
			return dvmScript_;

		return dvmScript_ = join(scripts, "dvm" ~ scriptExtension);
	}
	
	string env ()
	{
		if (env_.length > 0)
			return env_;
		
		return env_ = join(dvm, "env");
	}

	string compilers ()
	{
		if (compilers_.length > 0)
			return compilers_;

		return compilers_ = join(dvm, "compilers");
	}

	string archives ()
	{
		if (archives_.length > 0)
			return archives_;

		return archives_ = join(dvm, "archives");
	}

	string result ()
	{
		if (result_.length > 0)
			return result_;

		return result_ = join(tmp, "result");
	}
	
	string scripts ()
	{
		if (scripts_.length > 0)
			return scripts_;
		
		return scripts_ = join(dvm, "scripts");
	}

	string tmp ()
	{
		if (tmp_.length > 0)
			return tmp_;

		return tmp_ = join(dvm, "tmp");
	}
	
	string conf ()
	{
		if (conf_.length > 0)
			return conf_;
		
		return conf_ = join(bin, "dmd" ~ confExtension);
	}
	
	string tangoZip ()
	{
		if (tangoZip_.length > 0)
			return tangoZip_;
		
		return tangoZip_ = join(tmp, "tango.zip");
	}
	
	string tangoTmp ()
	{
		if (tangoTmp_.length > 0)
			return tangoTmp_;
		
		return tangoTmp_ = join(tangoUnarchived, "trunk");
	}
	
	string tangoUnarchived ()
	{
		if (tangoUnarchived_.length > 0)
			return tangoUnarchived_;
		
		return tangoUnarchived_ = join(tmp, "tango", "head");
	}
	
	string tangoBob ()
	{
		if (tangoBob_.length > 0)
			return tangoBob_;

		auto suffix = Options.instance.is64bit ? "64" : "32";
		auto path = join(tangoTmp, "build", "bin");
		
		version (darwin)
			path = join(path, "osx" ~ suffix);
		
		else version (freebsd)
			path = join(path, "freebsd" ~ suffix);
		
		else version (linux)
			path = join(path, "linux" ~ suffix);
		
		else version (Windows)
			path = join(path, "win" ~ suffix);
		
		else
			static assert(false, "Unhandled platform for installing Tango");
		
		return tangoBob_ = join(path, "bob" ~ executableExtension);
	}
	
	string tangoLib ()
	{
		if (tangoLib_.length > 0)
			return tangoLib_;
		
		return tangoLib_ = join(tangoTmp, tangoLibName ~ libExtension);
	}
	
	string tangoSrc ()
	{
		if (tangoSrc_.length)
			return tangoSrc_;
		
		return tangoSrc_ = join(tangoTmp, "tango");
	}
	
	string tangoObject ()
	{
		if (tangoObject_.length > 0)
			return tangoObject_;
		
		return tangoObject_ = join(tangoTmp, object_di);
	}
	
	string tangoVendor ()
	{
		if (tangoVendor_.length > 0)
			return tangoVendor_;
		
		return tangoVendor_ = join(tangoSrc, "core", "vendor", std);
	}

	string defaultEnv ()
	{
		if (defaultEnv_.length > 0)
			return defaultEnv_;

		return defaultEnv_ = join(env, "default");
	}

	string defaultBin ()
	{
		if (defaultBin_.length > 0)
			return defaultBin_;

		return defaultBin_ = join(dvm, bin, "dvm-default-dc");
	}
	
	string config ()
	{
		if (config_.length > 0)
			return config_;

		return config_ = join(dvm, "config");
	}
	
	string installed ()
	{
		if (installed_.length > 0)
			return installed_;

		return installed_ = join(config, "installed");
	}
}