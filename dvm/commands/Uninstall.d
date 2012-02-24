/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jun 3, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Uninstall;

import tango.io.device.File;
import tango.text.Util;

import dvm.commands.Command;
import mambo.core._;
import Path = dvm.io.Path;
import dvm.util._;

class Uninstall : Command
{
	private string installPath_;
	
	this (string name, string summary = "")
	{
		super(name, summary);
	}

	this ()
	{
		super("uninstall", "Uninstall one or many D compilers.");
	}

	void execute ()
	{
		println("Uninstalling dmd-", args.first);
		removeFiles;
	}
	
private:
	
	void removeFiles ()
	{
		verbose("Removing files:");
		
		auto dmd = "dmd-" ~ args.first;
		
		removeFile(Path.join(options.path.compilers, dmd));
		removeFile(Path.join(options.path.env, dmd));
		removeFile(Path.join(options.path.dvm, options.path.bin, dmd));
	}
	
	void removeFile (string path)
	{
		if (!Path.exists(path))
			return;
		
		verbose(options.indentation, path);
		Path.remove(path, true);
	}
}