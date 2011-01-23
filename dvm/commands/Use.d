/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Use;


import dvm.util.Util;
import tango.core.Exception;
import tango.text.convert.Format : format = Format;

import dvm.core._;
import dvm.dvm.Options;
import dvm.dvm.ShellScript;
import dvm.commands.Command;
import dvm.io.Path;

class Use : Command
{
	private
	{
		string envPath_;
	}
	
	this ()
	{
		super("use", "Setup current shell to use a specific D compiler version.");
	}
	
	void execute ()
	{
		loadEnvironment;
	}
	
private:
	
	void loadEnvironment ()
	{
		writeShellScript(createShellScript);
	}
	
	ShellScript createShellScript ()
	{
		verbose("creating shell script");
		auto sh = new ShellScript;
		sh.source(envPath);
		
		return sh;
	}
	
	void writeShellScript (ShellScript sh)
	{
		validatePath(envPath);
		sh.path = join(options.path.result);
		verbose(format(`installing "{}" as the current D compiler`, sh.path));
		sh.write;
	}
	
	string envPath ()
	{
		if (envPath_.length > 0)
			return envPath_;
		
		return envPath_ = join(options.path.dvm, options.path.env, "dmd-" ~ args.first);
	}	
}

template UseImpl ()
{

	

}