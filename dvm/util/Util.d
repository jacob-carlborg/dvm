/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Util;

import mambo.core.io;
import mambo.util.Use;

import dvm.dvm.Options;

Use!(void delegate (), bool) unless (bool value)
{
	Use!(void delegate (), bool) use;
	
	use.args[0] = (void delegate () dg, bool value) {
		if (value == false)
			dg();
	};
	
	use.args[1] = value;
	
	return use;
}

void verbose (ARGS...) (ARGS args)
{
	if (Options.instance.verbose)
		println(args);
}

void verboseRaw (ARGS...) (ARGS args)
{
	if (Options.instance.verbose)
		print(args);
}