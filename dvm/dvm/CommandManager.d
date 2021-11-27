/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.CommandManager;

import std.algorithm : sort;
import std.array : array;
import std.format : format;
import std.range : join, repeat;
import std.conv : to;

import dvm.commands.Command;
import dvm.dvm.Options;

class CommandManager
{
	private static CommandManager instance_;
    private Command[string] commands;

	private this () {}

	static CommandManager instance ()
	{
		if (instance_)
			return instance_;

		return instance_ = new typeof(this);
	}

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
        return commands.keys.sort.array;
    }

    string summary ()
    {
        string result;

        auto len = lenghtOfLongestCommand;
        auto options = Options.instance;

        foreach (name, _ ; commands)
        {
            auto command = this[name];
            result ~= format("%s%s%s%s%s\n",
                        options.indentation,
                        command.name,
                        " ".repeat(len - command.name.length).join,
                        options.indentation.repeat(options.numberOfIndentations).join,
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
