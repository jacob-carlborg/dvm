/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.CommandManager;

import tango.text.convert.Format;
import dvm.commands.Command;
import mambo.core.string;
import dvm.dvm.Options;
import dvm.util.Singleton;

class CommandManager
{
	mixin Singleton;
	
	private Command[string] commands;
	
	void register (string command)
	{
		commands[command] = null;
	}

	Command opIndex (string command)
	{
		if (auto c = command in commands)
			if (*c)
				return *c;
		
		auto c = createCommand(command);
		commands[command] = c;
		
		return c;
	}
	
	string[] names ()
	{
		return commands.keys.sort;
	}
	
	string summary ()
	{
		string result;
		
		auto len = lenghtOfLongestCommand;
		auto options = Options.instance;

		foreach (name, _ ; commands)
		{
			auto command = this[name];
			result ~= Format("{}{}{}{}{}\n",
						options.indentation,
						command.name,
						" ".repeat(len - command.name.length),
						options.indentation.repeat(options.numberOfIndentations),
						command.summary);
		}
		
		return result;
	}
	
	private Command createCommand (string command)
	{
		return cast(Command) ClassInfo.find(command).create;
	}
	
	private size_t lenghtOfLongestCommand ()
	{
		size_t len;
		
		foreach (name, _ ; commands)
		{
			auto command = this[name];
			
			if (command.name.length > len)
				len = command.name.length;
		}

		return len;
	}
}