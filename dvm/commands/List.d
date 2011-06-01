/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: May 31, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.List;

import tango.io.Console;
import tango.io.device.File;

import dvm.core._;
import dvm.commands.Command;
import dvm.io.Path;

class List : Command
{
	this (string name, string summary = "")
	{
		super(name, summary);
	}

	this ()
	{
		super("list", "Show currently installed D compilers");
	}

	void execute ()
	{
		if (!exists(options.path.installed))
		{
			println("No installed D compilers");
			return;
		}

		println("Installed D compilers:\n");
		auto file = new File(options.path.installed);
		Cout.stream.copy(file);
		println();
	}
}