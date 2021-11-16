/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: May 31, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.List;

import std.stdio : writeln;

import tango.io.vfs.FileFolder;

import dvm.commands.Command;
import Path = dvm.io.Path;

class List : Command
{
    this (string name, string summary = "")
    {
        super(name, summary);
    }

    this ()
    {
        super("list", "Show currently installed D compilers.");
    }

    override void execute ()
    {
        auto errorMessage = "No installed D compilers";

        if (!Path.exists(options.path.compilers))
        {
            writeln(errorMessage);
            return;
        }

        scope folder = new FileFolder(options.path.compilers);

        if (folder.self.folders == 0)
        {
            writeln(errorMessage);
            return;
        }

        writeln("Installed D compilers:\n");

        foreach (file ; folder)
            writeln(stripPath(file.toString));
    }

    private string stripPath (string name)
    {
        return Path.parse(name).file;
    }
}
