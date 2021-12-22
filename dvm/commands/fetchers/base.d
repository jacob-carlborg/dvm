/**
 * Copyright: Copyright (c) 2021 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Dec 21, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.fetchers.base;

import std.stdio : writeln;

abstract class Base
{
    protected immutable string[] args;

    this(string[] args)
    {
        this.args = args;
    }

    abstract void fetch();

protected:

    void fetch (string source, string destination)
    {
        if (Path.exists(destination))
            return;

        if (options.verbose)
        {
            writeln("Fetching:");
            writeln(options.indentation, "source: ", source);
            writeln(options.indentation, "destination: ", destination, '\n');
        }

        else
            writeln("Fetching: ", source);

        createPath(Path.parse(destination).folder);
        writeFile(downloadFile(source), destination);
    }
}
