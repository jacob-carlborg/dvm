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
	const int numberOfIndentations = 2;
	const Path path = Path();
	
	bool verbose = false;
}

private struct Path
{
	const bin = "bin";
	const src = "src";
	const lib = "lib";
	const import_ = "import";
	const license = "license.txt";
	const readme = "README.TXT";
	
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
		
		version (Posix)
		{
			const dvmDir = ".dvm";
			const string scriptExtension = "";
			const string executableExtension = "";
		}

		else version (Windows)
		{
			const dvmDir = "dvm";
			const scriptExtension = ".bat";
			const executableExtension = ".exe";
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

		return result_ = join(dvm, "result");
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
}