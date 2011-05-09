/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Application;

import tango.core.Exception;
import tango.io.device.File;
import tango.net.http.HttpGet;
import tango.text.Arguments;
import tango.text.convert.Format : Format;

import dvm.dvm._;
import dvm.core._;
import dvm.util._;

import dvm.commands._;
import dvm.commands.Install;

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
	
	void run (string[] args)
	{
		this.args = args;
		
		parseOptions();
	}
	
	private void registerCommands ()
	{
		commandManager.register("dvm.commands.Install.Install");
		commandManager.register("dvm.commands.Fetch.Fetch");
		commandManager.register("dvm.commands.Use.Use");
	}
	
	void handleCommand (string command, string[] args)
	{
		commandManager[command].invoke(args);
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
				default:
					return;
			}
		
			handleCommand(command, args[1 .. $]);			
		}			
	}
	
	void parseOptions ()
	{
		auto helpMessage = "Use the `-h' flag for help.";
		auto opts = new OptionParser;
		auto commands = CommandManager.instance.summary;
		auto help = false;
		
		opts.banner = "Usage: dvm [options] command [arg]";
		opts.separator("Version 0.2.0");
		opts.separator("");
		opts.separator("Commands:");
		opts.separator(commands);
		opts.separator("Options:");
		
		opts.on('d', "default", "Sets the default D compiler for new shells", {
			options.isDefault = true;
		});

		opts.on("64bit", "Installs the 64bit version of the compiler", {
			options.is64bit = true;
		});
		
		opts.on("32bit", "Installs the 32bit version of the compiler", {
			options.is64bit = false;
		});

		opts.on('t', "tango", "Installs Tango as the standard library", {
			options.tango = true;
		});

		opts.on('v', "verbose", "Show additional output.", {
			options.verbose = true;
		});
		
		opts.on('h', "help", "Show this message and exit.", {
			help = true;
		});

		if (args.length == 1 || help)
		{
			println(opts);
			println(helpMessage);
		}

		else
		{
			opts.on((string[] args) {
				handleArgs(args);
			});
			
			opts.parse(args[1 .. $]);
		}
	}
	
	void printCommands ()
	{
		
	}
}