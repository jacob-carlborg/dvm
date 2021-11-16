/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Util;

import std.stdio : writeln;

import dvm.dvm.Options;

void verbose (ARGS...) (ARGS args)
{
    if (Options.instance.verbose)
        writeln(args);
}

void verboseRaw (ARGS...) (ARGS args)
{
    if (Options.instance.verbose)
        writeln(args);
}
