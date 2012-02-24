/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Use;

import dvm.util.Util;
import tango.core.Exception;
import tango.text.convert.Format : format = Format;

import mambo.core._;
import dvm.dvm.Options;
import dvm.dvm.ShellScript;
import dvm.dvm.Wrapper;
import dvm.commands.Command;
import dvm.io.Path;
version (Windows) import DvmRegistry = dvm.util.DvmRegistry;
version (Windows) import dvm.util.Windows;

class Use : Command
{
	private
	{
		string envPath_;
		Wrapper wrapper;
	}
	
	this ()
	{
		super("use", "Setup current shell to use a specific D compiler version.");
	}
	
	void execute ()
	{
		loadEnvironment;
		installWrapper;

		version (Posix)
			setPermissions;

		version (Windows)
			updateRegistry;
	}
	
private:
	
	void loadEnvironment ()
	{
		auto shellScript = createShellScript;

		auto current = options.isDefault ? "default" : "current";
		verbose(format(`Installing "{}" as the {} D compiler`, args.first, current));

		writeShellScript(shellScript, options.path.result);

		version (Posix)
			if (options.isDefault)
			{
				verbose("Installing environment: ", options.path.defaultEnv);
				copy(options.path.result, options.path.defaultEnv);
			}
	}

	void installWrapper ()
	{
		wrapper.target = join(options.path.compilers, "dmd-" ~ args.first, options.path.bin, "dmd" ~ options.path.executableExtension);
		wrapper.path = join(options.path.dvm, options.path.bin, "dvm-current-dc" ~ options.path.scriptExtension);

		verbose("Installing wrapper: " ~ wrapper.path);

		if (exists(wrapper.path))
			dvm.io.Path.remove(wrapper.path);

		wrapper.write;

		if (options.isDefault)
		{
			verbose("Installing wrapper: ", options.path.defaultBin);
			copy(wrapper.path, options.path.defaultBin);
		}
	}

	version (Windows)
		void updateRegistry ()
		{
			if (options.isDefault)
			{
				auto dmdDir = join(options.path.compilers, "dmd-" ~ args.first, options.path.bin);
				DvmRegistry.updateEnvironment(options.path.binDir, dmdDir);
			
				DvmRegistry.checkSystemPath();
			
				broadcastSettingChange("Environment");
			}
		}

	version (Posix)
		void setPermissions ()
		{
			verbose("Setting permissions:");

			setPermission(wrapper.path, "+x");

			if (options.isDefault)
				setPermission(options.path.defaultBin, "+x");
		}

	version (Posix)
		void setPermission (string path, string mode)
		{
			verbose(options.indentation, "mode: ", mode);
			verbose(options.indentation, "file: ", path);

			permission(path, mode);
		}
	
	ShellScript createShellScript ()
	{
		verbose("Creating shell script");
		auto sh = new ShellScript;
		sh.echoOff;
		sh.source(Sh.quote(envPath));
		
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
		
		return envPath_ = native(join(options.path.env, "dmd-" ~ args.first ~ options.path.scriptExtension));
	}
}

template UseImpl ()
{

	

}