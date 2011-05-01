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
		auto shellScript = createShellScript;

		auto current = options.isDefault ? "default" : "current";
		verbose(format(`Installing "{}" as the {} D compiler`, args.first, current));

		writeShellScript(shellScript, options.path.result);

		if (options.isDefault)
			writeShellScript(shellScript, options.path.default_);
	}
	
	ShellScript createShellScript ()
	{
		verbose("Creating shell script");
		auto sh = new ShellScript;
		sh.source(envPath);
		
		return sh;
	}
	
	void writeShellScript (ShellScript sh, string path)
	{
		validatePath(envPath);
		sh.path = path;
		
		if (!exists(options.path.tmp))
			createFolder(options.path.tmp);
		
		sh.write;
	}
	
	string envPath ()
	{
		if (envPath_.length > 0)
			return envPath_;
		
		return envPath_ = join(options.path.env, "dmd-" ~ args.first);
	}	
}

template UseImpl ()
{

	

}