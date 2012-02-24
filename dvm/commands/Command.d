/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Command;

import dvm.dvm._;
import mambo.core.string;
import Path = dvm.io.Path;

abstract class Command
{
	string name;
	string summary;
	
	protected Args args;
	protected Options options;
	
	this () {}
	
	this (string name, string summary = "")
	{
		this.name = name;
		this.summary = summary;
		options = Options.instance;
	}
	
	abstract void execute ();
	
	void invoke (string[] args ...)
	{
		this.args.args = args;
		execute_;
	}
	
	void invoke (Args args)
	{
		this.args = args;
		execute_;
	}
	
	private void execute_ ()
	{
		deleteTmpDirectory;
		execute;
	}
	
	private void deleteTmpDirectory ()
	{
		if (Path.exists(options.path.tmp))
			Path.remove(options.path.tmp, true);
	}
}

private struct Args
{
	string[] args;
	
	string opIndex (size_t index)
	{
		if (index > args.length - 1 && empty)
			throw new MissingArgumentException("Missing argument(s)", __FILE__, __LINE__);
		
		return args[index];
	}
	
	string first ()
	{
		return opIndex(0);
	}
	
	string first (string arg)
	{
		if (empty)
			args ~= arg;
			
		else
			args[0] = arg;
		
		return arg;
	}
	
	string last ()
	{
		return opIndex(args.length - 1);
	}
	
	bool empty ()
	{
		return args.length == 0;
	}
	
	bool any ()
	{
		return !empty;
	}
}