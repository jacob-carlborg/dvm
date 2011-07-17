/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Application;

import tango.core.Exception;
import tango.io.device.File;
import tango.io.Stdout;
import tango.net.http.HttpGet;
import tango.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;
import tango.text.Arguments;
import tango.text.convert.Format : Format;

import dvm.dvm._;
import dvm.core._;
import dvm.util._;

static import dvm.commands._;

version (Windows)
{
	pragma(lib, "zlib.lib");
	pragma(lib, "Advapi32.lib");
}

class Application
{
	private static Application instance_;
	
	private
	{
		alias Format format;
		string[] args;
		Options options;
		CommandManager commandManager;
	}
	
	static Application instance ()
	{
		if (instance_)
			return instance_;
		
		return instance_ = new Application;
	}
	
	private this ()
	{
		options = Options.instance;
		commandManager = CommandManager.instance;

		registerCommands;
	}
	
	int run (string[] args)
	{
		this.args = args;
		
		return handleExceptions in {
			parseOptions();
			return EXIT_SUCCESS;
		};
	}
	
	Use!(int delegate ()) handleExceptions ()
	{
		Use!(int delegate ()) use;
		
		use.args[0] = (int delegate () dg) {
			try
				return dg();
				
			catch (DvmException e)
			{
				stderr.format("An error occurred: {}", e).flush;
				return EXIT_FAILURE;
			}
			
			catch (Exception e)
			{
				stderr.format("An unknown error occurred:").newline;
				throw e;
			}
		};
		
		return use;
	}
	
	Use!(int delegate ()) debugHandleExceptions ()
	{
		Use!(int delegate ()) use;
	
		use.args[0] = (int delegate () dg) {
			return dg();
		};
		
		return use;
	}
	
	private void registerCommands ()
	{
		commandManager.register("dvm.commands.Install.Install");
		commandManager.register("dvm.commands.Fetch.Fetch");
		commandManager.register("dvm.commands.Use.Use");
		commandManager.register("dvm.commands.List.List");
		commandManager.register("dvm.commands.Uninstall.Uninstall");
	}
	
	void handleArgs (string[] args)
	{
		if (args.length > 0)
		{	
			string command;
			
			switch (args[0])
			{
				case "install":	command = "dvm.commands.Install.Install"; break;
				case "fetch": command = "dvm.commands.Fetch.Fetch"; break;
				case "use": command = "dvm.commands.Use.Use"; break;
				case "list": command = "dvm.commands.List.List"; break;
				case "uninstall": command = "dvm.commands.Uninstall.Uninstall"; break;
				default:
					return unhandledCommand(args[0]);
			}
		
			handleCommand(command, args[1 .. $]);			
		}
	}
	
	void handleCommand (string command, string[] args)
	{
		commandManager[command].invoke(args);
	}
	
	void unhandledCommand (string command)
	{
		throw new DvmException("unrecognized command " ~ `"` ~ command ~ `"` ~ "\n", __FILE__, __LINE__);
	}
	
	void parseOptions ()
	{
		auto helpMessage = "Use the `-h' flag for help.";
		auto opts = new OptionParser;
		auto commands = CommandManager.instance.summary;
		auto help = false;
		
		opts.banner = "Usage: dvm [options] command [arg]";
		opts.separator("Version x.y.z");
		opts.separator("");
		opts.separator("Commands:");
		opts.separator(commands);
		opts.separator("Options:");
		
		opts.on('d', "default", "Sets the default D compiler for new shells.", {
			options.isDefault = true;
		});
		
		opts.on('l', "latest", "Gets the latest D compiler.", {
			options.latest = true;
		});
		
		version (Posix)
		{
			opts.on("64bit", "Installs the 64bit version of the compiler.", {
				options.is64bit = true;
			});
			
			opts.on("32bit", "Installs the 32bit version of the compiler.", {
				options.is64bit = false;
			});
		}
		
		opts.on('t', "tango", "Installs Tango as the standard library.", {
			options.tango = true;
		});

		opts.on('v', "verbose", "Show additional output.", {
			options.verbose = true;
		});
		
		opts.on("force", "Answer 'yes' to all prompts.", {
			options.force = true;
		});
		
		opts.on("decline", "Answer 'no' to all prompts.", {
			options.decline = true;
		});
		
		opts.on('h', "help", "Show this message and exit.", {
			help = true;
		});

		opts.on((string[] args) {
			if (options.force && options.decline)
				throw new InvalidOptionException("Cannot use both --force and --decline", __FILE__, __LINE__);
			
			else if (!help)
				handleArgs(args);
		});
	
		opts.parse(args[1 .. $]);
		
		if (args.length == 1 || help)
		{
			println(opts);
			println(helpMessage);
		}
	}
}